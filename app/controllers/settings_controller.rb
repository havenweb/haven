require 'mini_magick'
require 'stringio'

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
      # @setting.save # Save will be called later by @setting.update
    end

    # Favicon Logic
    if setting_params[:remove_favicon] == '1'
      @setting.favicon_original.purge if @setting.favicon_original.attached?
      @setting.favicon_ico.purge if @setting.favicon_ico.attached?
      @setting.favicon_apple_touch.purge if @setting.favicon_apple_touch.attached?
      @setting.favicon_32x32.purge if @setting.favicon_32x32.attached?
      @setting.favicon_16x16.purge if @setting.favicon_16x16.attached?
      @setting.favicon_512x512.purge if @setting.favicon_512x512.attached?
    elsif setting_params[:favicon_original].present?
      @setting.favicon_original.attach(setting_params[:favicon_original])

      if @setting.favicon_original.attached? && @setting.favicon_original.blob.content_type.start_with?('image/')
        begin
          image_blob = @setting.favicon_original.blob.download
          image = MiniMagick::Image.read(image_blob)

          unless image.width == image.height && image.width >= 512
            @setting.favicon_original.purge # Remove the invalid attachment
            flash[:alert] = "Favicon must be square and at least 512x512 pixels."
            redirect_to settings_edit_path
            return
          else
            # === Variant Generation ===
            @setting.favicon_ico.purge if @setting.favicon_ico.attached?
            @setting.favicon_apple_touch.purge if @setting.favicon_apple_touch.attached?
            @setting.favicon_32x32.purge if @setting.favicon_32x32.attached?
            @setting.favicon_16x16.purge if @setting.favicon_16x16.attached?
            @setting.favicon_512x512.purge if @setting.favicon_512x512.attached?

            @setting.favicon_ico.attach(
              io: StringIO.new(image.format("ico") { |c| c.resize "48x48" }.to_blob),
              filename: 'favicon.ico',
              content_type: 'image/vnd.microsoft.icon'
            )

            @setting.favicon_apple_touch.attach(
              io: StringIO.new(image.format("png") { |c| c.resize "180x180" }.to_blob),
              filename: 'apple-touch-icon.png',
              content_type: 'image/png'
            )

            @setting.favicon_32x32.attach(
              io: StringIO.new(image.format("png") { |c| c.resize "32x32" }.to_blob),
              filename: 'favicon-32x32.png',
              content_type: 'image/png'
            )

            @setting.favicon_16x16.attach(
              io: StringIO.new(image.format("png") { |c| c.resize "16x16" }.to_blob),
              filename: 'favicon-16x16.png',
              content_type: 'image/png'
            )

            @setting.favicon_512x512.attach(
              io: StringIO.new(image.format("png") { |c| c.resize "512x512" }.to_blob),
              filename: 'favicon-512x512.png',
              content_type: 'image/png'
            )
          end
        rescue MiniMagick::Error => e
          @setting.favicon_original.purge if @setting.favicon_original.attached?
          flash[:alert] = "Error processing favicon: #{e.message}"
          redirect_to settings_edit_path
          return
        end
      else
        if @setting.favicon_original.attached? # It was attached, but not an image
          @setting.favicon_original.purge
          flash[:alert] = "Uploaded favicon is not a valid image type."
          redirect_to settings_edit_path
          return
        end
      end
    end

    setting_params_for_update = setting_params.except(:favicon_original, :remove_favicon)
    if @setting.update(setting_params_for_update)
      flash[:notice] = "Settings Saved"
      redirect_to settings_edit_path
    else
      flash[:alert] = "Settings could not be saved."
      # Ensure the view has the @setting object, especially if rendering edit
      render :edit, status: :unprocessable_entity
    end
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
    params.require(:setting).permit(:title, :subtitle, :author, :css, :byline, :comments, :favicon_original, :remove_favicon)
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
