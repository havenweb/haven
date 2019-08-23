class SettingsController < ApplicationController
  def show
    @setting = get_setting
  end

  def edit
    @setting = get_setting
  end

  def update
    # render plain: params[:setting].inspect
    @setting = get_setting
    @setting.update(setting_params)
    redirect_to settings_url
  end


  private

  def get_setting
    Setting.find(1)
  rescue
    Setting.new
  end
  def setting_params
    params.require(:setting).permit(:title, :subtitle, :author, :visibility, :css)
  end
end
