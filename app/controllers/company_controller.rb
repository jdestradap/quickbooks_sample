class CompanyController < ApplicationController
  before_filter :find_company

  def show
    @render_blue_dot = @company.connected_to_intuit?
    @blue_dot_url = company_proxy_path(@company)
  end

  def proxy
    response = @company.intuit_token.get("https://appcenter.intuit.com/api/v1/Account/AppMenu")
    status = response.code
    body = response.body
    render :text => body, :status => status
  end

  def disconnect
    if(@company.connected_to_intuit?)
      @company.intuit_token.get("https://appcenter.intuit.com/api/v1/Connection/Disconnect")
      @company.update_attributes(
        :intuit_access_token => nil,
        :intuit_access_secret => nil
      )
    end
    redirect_to company_path(@company)
  end

  private
  def find_company
    @company = Company.find(params[:id])
  end
end