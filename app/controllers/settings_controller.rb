class SettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_admin, except:[:style]

  IMPORTANT_PREFIX = 
<<-HEREDOC
#csscontent()
  {
HEREDOC

  IMPORTANT_SUFFIX = 
<<-HEREDOC   
  }

& {
  #csscontent() !important
}
HEREDOC

  def show
    @setting = SettingsController.get_setting
  end

  def edit
    @setting = SettingsController.get_setting
  end

  def update
    @setting = SettingsController.get_setting
    less = IMPORTANT_PREFIX + setting_params[:css] + IMPORTANT_SUFFIX
    less_parser = Less::Parser.new
    compiled_css = less_parser.parse(less).to_css(:compress => true)
    @setting.compiled_css = compiled_css
    @setting.css_hash = Digest::MD5.hexdigest(compiled_css)
    @setting.update(setting_params)
    redirect_to posts_path
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
    params.require(:setting).permit(:title, :subtitle, :author, :css, :byline)
  end
end
