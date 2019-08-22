class SettingsController < ApplicationController
  def show
    # @setting = Setting.find(1) || Setting.new
  end

  def edit
    # @setting = Setting.find(1) || Setting.new
  end

  def update
    render plain: params[:setting].inspect
    # @setting = Setting.find(1) || Setting.new
    # @setting.update(params)  ##todo, fix this with allowed params
  end
end
