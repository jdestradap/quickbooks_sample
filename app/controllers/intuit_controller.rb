class IntuitController < ApplicationController
  before_filter :login_required, :only => [:sso_link, :connect, :callback]

  # IA OAUTH

  def connect
    binding.pry
    consumer = Intuit::API.get_consumer(AppConfig["intuit_consumer_key"], AppConfig["intuit_consumer_secret"])
    token = consumer.get_request_token(:oauth_callback => intuit_callback_url)
    session[:request_token] = token
    redirect_to Intuit::API.authorize_url(token.token)
  end

  def callback
    at = session[:request_token].get_access_token(:oauth_verifier => params[:oauth_verifier])
    session[:request_token] = nil
    if(@company = Company.where(:realm => params["realmId"]).first)
      @company.update_attributes(:owner => current_user, :intuit_access_token => at.token, :intuit_access_secret => at.secret)
    else
      @company = Company.create(
        :intuit_access_token => at.token,
        :intuit_access_secret => at.secret,
        :realm => params["realmId"],
        :owner => current_user,
        :name => "",
        :is_qbo => params["dataSource"] == "QBO"
      )
    end
    b = Crack::XML.parse(@company.intuit_token.get("https://services.intuit.com/sb/company/v2/availableList").body)
    b = b["RestResponse"]["CompaniesMetaData"]["CompanyMetaData"]
    if(b.is_a?(Hash))
      name = b
    else
      name = b.select { |x| x["ExternalRealmId"].to_s == @company.realm.to_s }.first
    end
    if(name)
      name = name["QBNRegisteredCompanyName"]
    else
      name = "Untitled"
    end
    @company.name = name
    @company.save
    if(session[:from_intuit])
      redirect_to root_path
    else
      render :layout => false
    end
  end

  # OpenID SSO
  def sso
    begin
      response = openid_consumer.begin "https://appcenter.intuit.com/identity-me"
    rescue OpenID::OpenIDError => e
      redirect_to root_path, :notice => "Uh oh! Intuit SSO Error"
      return
    end
    session[:from_intuit] = params[:fromintuit] || false 
    sregreq = OpenID::SReg::Request.new
    sregreq.request_fields(['email','fullname'])
    response.add_extension(sregreq)
    if response.send_redirect?(root_url, complete_intuit_sso_url, false)
      redirect_to response.redirect_url(root_url, complete_intuit_sso_url, false)
    else
      redirect_to root_path, :notice => "Uh oh! Intuit SSO Error"
    end
  end

  def sso_complete
    parameters = params.reject{|k,v|request.path_parameters[k]}
    parameters.delete("controller")
    parameters.delete("action")
    response = openid_consumer.complete(parameters, complete_intuit_sso_url)
    Rails.logger.debug(response.status == OpenID::Consumer::FAILURE)
    case response.status
    when OpenID::Consumer::FAILURE
      redirect_to (logged_in? ? root_path : login_path), :notice => (response.display_identifier ? "Verification of #{response.display_identifier} failed: #{response.message}" : "Verification failed: #{response.message}")
      return
    when OpenID::Consumer::SUCCESS
      sreg_resp = OpenID::SReg::Response.from_success_response(response)
      if response.identity_url && u = User.find_by_openid_identifier(response.identity_url)
        UserSession.create(u)
        if(session[:from_intuit])
          render :action => "ia", :layout => false
        else
          redirect_to root_path, :notice => "You have logged in!"
        end
      elsif logged_in?
        session[:oid] = response.identity_url
        render :action => "verify_link"
      elsif u = User.find_by_email(sreg_resp["email"])
        # redirect to reenter password to verify link
        # as intuit doesn't verify emails, we don't want to autolink
        redirect_to login_path, :notice => "A user already exists with that email, you'll need to login with that account first"
      else
        UserSession.create(User.create(:email => sreg_resp["email"], :openid_identifier => response.identity_url))
        if(session[:from_intuit])
          render :action => "ia", :layout => false
        else
          redirect_to root_path, :notice => "Welcome #{sreg_resp['fullname']}"
        end
      end
      return
    when OpenID::Consumer::SETUP_NEEDED
      redirect_to root_path, :notice => "Immediate request failed - Setup Needed"
    when OpenID::Consumer::CANCEL
      redirect_to root_path, :notice => "OpenID transaction cancelled."
    else
    end
    redirect_to root_path
  end

  def sso_link
    current_user.openid_identifier = session[:oid]
    current_user.save
    redirect_to root_path, :notice => "You have successfully linked your account!"
  end

  def xrds
    render :layout => false
  end

  protected

    def openid_consumer
      @openid_consumer ||= OpenID::Consumer.new(session,      
        OpenID::Store::Filesystem.new("#{Rails.root}/tmp/openid"))
    end

end
