class ApplicationController < ActionController::Base
  def self.get_settings
    return Setting.first || Setting.new
  end


  private
  
  def verify_admin
    if current_user.admin != 1
      redirect_to posts_path
    end
  end 
end
