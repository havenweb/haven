require 'mini_magick'
require 'stringio'

class FaviconsController < ApplicationController
  # No authentication needed for favicons typically
  skip_before_action :authenticate_user!, only: [:serve_ico], raise: false
  skip_before_action :verify_admin, only: [:serve_ico], raise: false


  def serve_ico
    setting = SettingsController.get_setting # Access settings

    if setting.favicon_original.attached? && setting.favicon_original.variable?
      begin
        # Download original and process
        original_blob_data = setting.favicon_original.blob.download
        image = MiniMagick::Image.read(original_blob_data)
        
        # Configure ICO generation for a single 48x48px ICO
        image.resize "48x48" # Resize to a common ICO dimension
        image.format "ico"   # Convert to ICO format
        
        ico_data = image.to_blob

        send_data ico_data, type: 'image/vnd.microsoft.icon', disposition: 'inline', filename: 'favicon.ico'
      rescue ActiveStorage::Error, MiniMagick::Error => e
        Rails.logger.error "Error generating custom favicon.ico: #{e.message}"
        serve_default_favicon
      end
    else
      serve_default_favicon
    end
  end

  private

  def serve_default_favicon
    # Serve the static favicon from public/favicon.ico
    # Ensure this file exists.
    default_favicon_path = Rails.root.join('public', 'favicon.ico')
    if File.exist?(default_favicon_path)
      send_file default_favicon_path, type: 'image/vnd.microsoft.icon', disposition: 'inline'
    else
      # Fallback if public/favicon.ico is missing
      Rails.logger.warn "Default public/favicon.ico not found."
      head :not_found
    end
  end
end
