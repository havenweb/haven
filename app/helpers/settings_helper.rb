module SettingsHelper
  # Helper to get the global settings object
  def current_settings
    @current_settings ||= SettingsController.get_setting
  end

  def custom_favicon_ico_url
    # This path will be handled by a dedicated controller (e.g., FaviconsController#serve_ico)
    # to serve the dynamic ICO from favicon_original or the default static favicon.ico.
    '/favicon.ico'
  end

  def custom_favicon_apple_touch_url
    if current_settings.favicon_original.attached? && current_settings.favicon_original.variable?
      begin
        url_for(current_settings.favicon_original.variant(resize_to_fill: [180, 180]))
      rescue ActiveStorage::InvariableError
        # Fallback if this specific original cannot be varianted
        ActionController::Base.helpers.asset_path('apple.png')
      end
    else
      ActionController::Base.helpers.asset_path('apple.png')
    end
  end

  def custom_favicon_32x32_url
    if current_settings.favicon_original.attached? && current_settings.favicon_original.variable?
      begin
        url_for(current_settings.favicon_original.variant(resize_to_fill: [32, 32]))
      rescue ActiveStorage::InvariableError
        ActionController::Base.helpers.asset_path('favicon-32x32.png')
      end
    else
      ActionController::Base.helpers.asset_path('favicon-32x32.png')
    end
  end

  def custom_favicon_16x16_url
    if current_settings.favicon_original.attached? && current_settings.favicon_original.variable?
      begin
        url_for(current_settings.favicon_original.variant(resize_to_fill: [16, 16]))
      rescue ActiveStorage::InvariableError
        ActionController::Base.helpers.asset_path('favicon-16x16.png')
      end
    else
      ActionController::Base.helpers.asset_path('favicon-16x16.png')
    end
  end

  def custom_favicon_512x512_url
    if current_settings.favicon_original.attached? && current_settings.favicon_original.variable?
      begin
        url_for(current_settings.favicon_original.variant(resize_to_fill: [512, 512]))
      rescue ActiveStorage::InvariableError
        ActionController::Base.helpers.asset_path('512.png')
      end
    else
      ActionController::Base.helpers.asset_path('512.png')
    end
  end
end
