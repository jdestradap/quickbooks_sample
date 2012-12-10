class HomeController < ApplicationController
  before_filter :login_with_xrds

  def index
  end

  protected

    def login_with_xrds
      response.headers['X-XRDS-Location'] = intuit_xrds_url
      if(request.accepts.include? "application/xrds+xml")
        render :text => "ok"
      else
        login_required
      end
    end

end
