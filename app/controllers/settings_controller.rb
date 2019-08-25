class SettingsController < ApplicationController
  def show
    @setting = SettingsController.get_setting
  end

  def edit
    @setting = SettingsController.get_setting
  end

  def update
    @setting = SettingsController.get_setting
    @setting.update(setting_params)
    redirect_to settings_url
  end

  def style
    @setting = SettingsController.get_setting
  end

  def self.get_setting
    Setting.find(1)
  rescue
    Setting.new
  end


  private

  def setting_params
    params.require(:setting).permit(:title, :subtitle, :author, :visibility, :css)
  end
end
