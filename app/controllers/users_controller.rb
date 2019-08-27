class UsersController < ApplicationController
  def index
    @users = User.order(email: :asc)
  end
  
  def new
    @user = User.new
  end

  def create
    @password = Devise.friendly_token.first(20)
    admin = params[:user][:role] == "admin" ? 1 : 0
    email = params[:user][:email]
    name = params[:user][:name]
    @user = User.create! email: email, name: name, admin: admin, password: @password
    @verb = "created"
    render :show
  end

  def resetpassword
    @password = Devise.friendly_token.first(20)
    @user = User.find(params[:id])
    @user.update_attributes(password: @password)
    @verb = "updated"
    render :show
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy
    redirect_to users_path
  end
end
