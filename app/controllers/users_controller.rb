class UsersController < ApplicationController
  layout 'login'
  before_filter :logout_required, :only => [:new, :create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      binding.pry
      redirect_back_or_default root_path, :notice => "Welcome #{@user.first_name}!"
    else
      render :action => :new
    end
  end
end
