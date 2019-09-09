class ApplicationController < ActionController::Base
  def self.get_settings
    return Setting.first || Setting.new
  end


  private

#  def after_sign_out_path_for(resource_or_scope)
#    puts "DEBUG:  I got called!! "
#    root_path
#  end
end
