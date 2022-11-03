class ApplicationController < ActionController::Base

  before_action :configure_permitted_parameters, if: :devise_controller?

  def self.get_settings
    return Setting.first || Setting.new
  end

  def check_basic_auth
    basic_auth_header = request.authorization
    if basic_auth_header.nil?
      return false
    end
    credentials = Base64.decode64(basic_auth_header.split("Basic ").last)
    basic_auth_user, basic_auth_pass = credentials.split(":")
    if (basic_auth_user.nil? || basic_auth_pass.nil?)
      return false
    end
    user = User.find_by(basic_auth_username: basic_auth_user)
    if (user.nil? || user.basic_auth_password != basic_auth_pass)
      return false
    end
    return true
  end

  private
  
  def verify_admin
    if current_user.admin != 1
      redirect_to posts_path
    end
  end 
  
  def verify_publisher
    if current_user.admin < 1 # 1 is admin, 2 is publisher
      redirect_to posts_path
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end
end
