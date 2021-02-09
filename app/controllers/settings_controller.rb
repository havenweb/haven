class SettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_admin, except:[:style, :show_fonts]

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
    begin
      compiled_css = less_parser.parse(less).to_css(:compress => true)
      @setting.compiled_css = compiled_css
      @setting.css_hash = Digest::MD5.hexdigest(compiled_css)
    rescue
      flash[:alert] = "Your CSS is not valid"
      redirect_to settings_edit_path
      return
    end
    @setting.update(setting_params)
    redirect_to posts_path
  end

  # Used to generate a CSS file that defines the fonts
  def show_fonts
    @setting = SettingsController.get_setting
  end

  def edit_fonts
    @setting = SettingsController.get_setting
  end

  def create_font
    @setting = SettingsController.get_setting
    @setting.fonts.attach params[:font]
    @setting.save!
    set_font_hash
    redirect_to edit_fonts_path
  end

  def destroy_font
    @setting = SettingsController.get_setting
    @setting.fonts.find(params[:font_id]).purge
    @setting.save!
    set_font_hash
    redirect_to edit_fonts_path
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
    params.require(:setting).permit(:title, :subtitle, :author, :css, :byline, :comments)
  end

  def set_font_hash
    setting = SettingsController.get_setting
    setting.font_hash = setting.fonts.hash.to_s
    setting.save!
  end 

end
