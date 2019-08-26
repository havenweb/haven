class UsersController < ApplicationController
  def index
    @users = User.order(email: :asc)
  end
  
  def new
    @user = User.new
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy
    redirect_to users_path
  end
end
