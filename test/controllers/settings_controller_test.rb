require 'test_helper'

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Assuming you have an admin user fixture named :admin_user
    # e.g., in test/fixtures/users.yml:
    # admin_user:
    #   email: admin@example.com
    #   encrypted_password: <%= Devise::Encryptor.digest(User, 'password') %>
    #   admin: 1
    @admin_user = users(:admin_user) 
    sign_in @admin_user # Devise test helper

    @setting = SettingsController.get_setting
    # Ensure the setting record is persisted so attachments can be saved to it.
    @setting.save! if @setting.new_record?
  end

  # --- Test Successful Favicon Upload and Variant Generation ---
  test "should upload valid favicon, generate variants, and save settings" do
    patch setting_path(@setting), params: {
      setting: {
        favicon_original: fixture_file_upload('files/favicon_valid_512x512.png', 'image/png')
      }
    }
    assert_redirected_to settings_edit_path, "Should redirect to settings edit path after successful upload"
    assert_equal "Settings Saved", flash[:notice], "Flash notice should indicate settings were saved"

    @setting.reload # Reload from DB to see attachment changes
    assert @setting.favicon_original.attached?, "Original favicon should be attached"
    assert @setting.favicon_ico.attached?, "ICO variant should be attached"
    assert @setting.favicon_apple_touch.attached?, "Apple Touch variant should be attached"
    assert @setting.favicon_32x32.attached?, "32x32 PNG variant should be attached"
    assert @setting.favicon_16x16.attached?, "16x16 PNG variant should be attached"
    assert @setting.favicon_512x512.attached?, "512x512 PNG variant should be attached"
  end

  # --- Test Validation: Image Too Small ---
  test "should reject favicon if image is too small" do
    patch setting_path(@setting), params: {
      setting: {
        favicon_original: fixture_file_upload('files/favicon_invalid_200x200.png', 'image/png')
      }
    }
    assert_redirected_to settings_edit_path, "Should redirect to settings edit path on validation error"
    assert_match /Favicon must be square and at least 512x512 pixels/, flash[:alert], "Flash alert should indicate size validation error"
    
    @setting.reload
    assert_not @setting.favicon_original.attached?, "Original favicon should NOT be attached if too small"
    assert_not @setting.favicon_ico.attached?, "ICO variant should NOT be attached if original is invalid"
  end

  # --- Test Validation: Image Not Square ---
  test "should reject favicon if image is not square" do
    patch setting_path(@setting), params: {
      setting: {
        favicon_original: fixture_file_upload('files/favicon_invalid_512x400.png', 'image/png')
      }
    }
    assert_redirected_to settings_edit_path, "Should redirect to settings edit path on validation error"
    assert_match /Favicon must be square and at least 512x512 pixels/, flash[:alert], "Flash alert should indicate aspect ratio validation error"

    @setting.reload
    assert_not @setting.favicon_original.attached?, "Original favicon should NOT be attached if not square"
  end

  # --- Test Validation: Non-Image File Upload ---
  test "should reject favicon if file is not an image" do
    patch setting_path(@setting), params: {
      setting: {
        favicon_original: fixture_file_upload('files/not_an_image.txt', 'text/plain')
      }
    }
    assert_redirected_to settings_edit_path, "Should redirect to settings edit path on file type error"
    assert_equal "Uploaded favicon is not a valid image type.", flash[:alert], "Flash alert should indicate invalid file type"

    @setting.reload
    assert_not @setting.favicon_original.attached?, "Original favicon should NOT be attached if not an image"
  end

  # --- Test Favicon Removal ---
  test "should remove custom favicon and all its variants" do
    # 1. Setup: Attach a valid favicon and ensure variants are generated
    patch setting_path(@setting), params: {
      setting: {
        favicon_original: fixture_file_upload('files/favicon_valid_512x512.png', 'image/png')
      }
    }
    @setting.reload
    assert @setting.favicon_original.attached?, "Setup for removal test failed: Original favicon did not attach."
    assert @setting.favicon_ico.attached?, "Setup for removal test failed: ICO variant did not attach."

    # 2. Test Removal
    patch setting_path(@setting), params: {
      setting: {
        remove_favicon: '1'
        # No other params needed, remove_favicon takes precedence
      }
    }
    assert_redirected_to settings_edit_path, "Should redirect to settings edit path after removal"
    assert_equal "Settings Saved", flash[:notice], "Flash notice should indicate settings were saved after removal"

    @setting.reload
    assert_not @setting.favicon_original.attached?, "Original favicon should be removed"
    assert_not @setting.favicon_ico.attached?, "ICO variant should be removed"
    assert_not @setting.favicon_apple_touch.attached?, "Apple Touch variant should be removed"
    assert_not @setting.favicon_32x32.attached?, "32x32 PNG variant should be removed"
    assert_not @setting.favicon_16x16.attached?, "16x16 PNG variant should be removed"
    assert_not @setting.favicon_512x512.attached?, "512x512 PNG variant should be removed"
  end
end
