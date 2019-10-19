class ApplicationController < ActionController::Base

  before_action :configure_permitted_parameters, if: :devise_controller?

  def self.get_settings
    return Setting.first || Setting.new
  end


  private
  
  def verify_admin
    if current_user.admin != 1
      redirect_to posts_path
    end
  end 

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end
end
