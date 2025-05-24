module SettingsHelper
  # Helper to get the global settings object
  # This replicates the controller's way of getting settings.
  # Consider if there's a more conventional helper way, but this is direct.
  def current_settings
    @current_settings ||= SettingsController.get_setting
  end

  def custom_favicon_ico_url
    if current_settings.favicon_ico.attached?
      url_for(current_settings.favicon_ico)
    else
      ActionController::Base.helpers.asset_path('favicon.ico')
    end
  end

  def custom_favicon_apple_touch_url
    if current_settings.favicon_apple_touch.attached?
      url_for(current_settings.favicon_apple_touch)
    else
      ActionController::Base.helpers.asset_path('apple.png') # Assuming default is 'apple.png' in assets or public
    end
  end

  def custom_favicon_32x32_url
    if current_settings.favicon_32x32.attached?
      url_for(current_settings.favicon_32x32)
    else
      # Fallback for 32x32. If public/favicon-32x32.png exists, use it.
      # Otherwise, maybe no specific fallback or point to the main .ico
      # For now, let's assume a default static asset might exist or this link might be omitted if no custom.
      # To be safe, we can check if a default is expected or if it should return nil/empty.
      # For now, let's point to a hypothetical default static asset.
      # If the app doesn't have default 16x16 and 32x32 PNGs, these could return nil
      # and the layout would need to handle that (e.g., not render the link tag).
      # The original layout had:
      # <link rel="icon" href="/icon.svg" type="image/svg+xml" sizes="any" />
      # It did not have separate 16x16 or 32x32 png links by default, relying on favicon.ico and the SVG.
      # Let's provide fallbacks assuming these defaults could be added to /public or assets.
      # If not, the layout update will need to be conditional.
      ActionController::Base.helpers.asset_path('favicon-32x32.png')
    end
  end

  def custom_favicon_16x16_url
    if current_settings.favicon_16x16.attached?
      url_for(current_settings.favicon_16x16)
    else
      ActionController::Base.helpers.asset_path('favicon-16x16.png')
    end
  end

  # This one might be used by the manifest.webmanifest or other places.
  def custom_favicon_512x512_url
    if current_settings.favicon_512x512.attached?
      url_for(current_settings.favicon_512x512)
    else
      ActionController::Base.helpers.asset_path('512.png') # Default path from original layout
    end
  end
end
