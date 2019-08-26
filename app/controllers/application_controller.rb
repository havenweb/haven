class ApplicationController < ActionController::Base
  def self.get_settings
    return Setting.first || Setting.new
  end
end
