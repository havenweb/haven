class SettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_admin, except:[:style, :show_fonts]

  def show
    @setting = SettingsController.get_setting
  end

  def edit
    @setting = SettingsController.get_setting
  end

  def update
    @setting = SettingsController.get_setting
    unless setting_params[:css].nil? or setting_params[:css].empty?
      begin
        validate_css(setting_params[:css])
      rescue
        flash[:alert] = "Your CSS is not valid"
        redirect_to settings_edit_path
        return
      end
      parser = CssParser::Parser.new
      parser.load_string! setting_params[:css]
      parser.each_rule_set do |ruleset|
        d = ruleset.instance_eval{declarations}
        dd = d.instance_eval{declarations}
        dd.each do |k,v|
          v.important = true
        end
      end
      compiled_css = parser.to_s
      @setting.compiled_css = compiled_css
      @setting.css_hash = Digest::MD5.hexdigest(compiled_css)
      @setting.save
    end
    @setting.update(setting_params)
    flash[:notice] = "Settings Saved"
    redirect_to settings_edit_path
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
    s = Setting.first
    if s.nil?
      s = Setting.new
    end
    s
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

  # ignore output, throws error on validation issues
  def validate_css(css_string)
    SassC::Engine.new(css_string, style: :compressed).render
  end
end
