class LoginLinksController < ApplicationController
  def validate
    login_link = LoginLink.where(token: params[:token]).first

    if login_link.nil?
      flash[:alert] = "Invalid token, please contact the owner of this site for help"
      redirect_to new_user_session_path
    else
      sign_in(login_link.user, scope: :user)
      flash[:notice] = "Hi #{login_link.user.name}, you have signed in"
      redirect_to root_path
    end
  end
end
