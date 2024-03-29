class ApplicationController < ActionController::Base
  protect_from_forgery

  helper_method :current_user_session, :current_user, :logged_in?
  
  private
    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      @current_user_session = UserSession.find
    end
    
    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.record
    end
    
    def logged_in?
      return !!current_user
    end
    
    def login_required
      unless logged_in?
        store_location
        redirect_to login_path, :alert => "You must be logged in to access that page!"
        return false
      end
    end
    
    def logout_required
      unless !logged_in?
        redirect_to root_path
        return false
      end
    end
    
    def store_location
      session[:return_to] = request.request_uri
    end
    
    def redirect_back_or_default(default, opts = {})
      redirect_to(session[:return_to] || default, opts)
      session[:return_to] = nil
    end
end
