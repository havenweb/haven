require "application_system_test_case"

class FaviconManagementTest < ApplicationSystemTestCase
  setup do
    @admin_user = users(:admin_user) # Make sure you have a fixture users.yml with :admin_user
    login_as @admin_user, scope: :user # Devise system test helper
    @setting = SettingsController.get_setting
    @setting.save! if @setting.new_record? # Ensure it's persisted
  end

  test "uploading a valid favicon and seeing it applied" do
    visit settings_edit_path

    # Detach any existing favicons to ensure a clean test run for assertions
    # This needs to be done via model interaction as UI might not allow removal before new upload
    if @setting.favicon_original.attached?
      @setting.favicon_original.purge
      @setting.favicon_ico.purge if @setting.favicon_ico.attached?
      @setting.favicon_apple_touch.purge if @setting.favicon_apple_touch.attached?
      @setting.favicon_32x32.purge if @setting.favicon_32x32.attached?
      @setting.favicon_16x16.purge if @setting.favicon_16x16.attached?
      @setting.favicon_512x512.purge if @setting.favicon_512x512.attached?
      @setting.save! # Persist these purges
    end
    visit settings_edit_path # Re-visit the page to reflect the purged state

    attach_file "setting_favicon_original", Rails.root.join("test/fixtures/files/favicon_valid_512x512.png")
    click_on "Save Settings"

    assert_text "Settings Saved"
    @setting.reload # Reload to get the latest attachment data

    # Check for preview image: using a more specific selector if possible, e.g., by id or class
    # For now, checking for an image whose src contains the filename
    assert_selector "img[src*='#{Regexp.escape(@setting.favicon_original.filename.to_s)}']"

    # Check <link> tags in head (these are invisible elements)
    # The href will contain a representation of the blob, often including the filename
    assert_selector "link[rel='icon'][sizes='48x48'][href*='#{@setting.favicon_ico.filename.to_s}']", visible: false
    assert_selector "link[rel='icon'][type='image/png'][sizes='16x16'][href*='#{@setting.favicon_16x16.filename.to_s}']", visible: false
    assert_selector "link[rel='icon'][type='image/png'][sizes='32x32'][href*='#{@setting.favicon_32x32.filename.to_s}']", visible: false
    assert_selector "link[rel='apple-touch-icon'][href*='#{@setting.favicon_apple_touch.filename.to_s}']", visible: false
    # The 512x512 is not directly linked in the HTML head by default, but used by manifest/etc.
    # So, no direct assert_selector for a <link> tag for favicon_512x512 in the head here.
  end

  test "attempting to upload an invalid favicon (too small)" do
    visit settings_edit_path

    # Optional: Ensure no favicon is set to simplify assertion of default links
    if @setting.favicon_original.attached?
      @setting.favicon_original.purge_later # Or .purge if not in a transaction
      # Purge variants too
      @setting.favicon_ico.purge_later if @setting.favicon_ico.attached?
      @setting.favicon_apple_touch.purge_later if @setting.favicon_apple_touch.attached?
      # ... and so on for other variants
      # Note: purge_later might not complete before next assertions in a system test.
      # For system tests, direct purge and re-visit or a dedicated cleanup step is safer.
      @setting.favicon_original.purge
      @setting.save!
    end
    visit settings_edit_path # Re-visit

    attach_file "setting_favicon_original", Rails.root.join("test/fixtures/files/favicon_invalid_200x200.png")
    click_on "Save Settings"

    assert_text "Favicon must be square and at least 512x512 pixels."
    @setting.reload
    assert_not @setting.favicon_original.attached?

    # Assert that the default favicon links are still in place
    default_ico_path = ActionController::Base.helpers.asset_path('favicon.ico')
    assert_selector "link[rel='icon'][sizes='48x48'][href='#{default_ico_path}']", visible: false
    
    default_apple_path = ActionController::Base.helpers.asset_path('apple.png')
    assert_selector "link[rel='apple-touch-icon'][href='#{default_apple_path}']", visible: false

    default_16_path = ActionController::Base.helpers.asset_path('favicon-16x16.png')
    assert_selector "link[rel='icon'][type='image/png'][sizes='16x16'][href='#{default_16_path}']", visible: false
    
    default_32_path = ActionController::Base.helpers.asset_path('favicon-32x32.png')
    assert_selector "link[rel='icon'][type='image/png'][sizes='32x32'][href='#{default_32_path}']", visible: false
  end

  test "removing a custom favicon" do
    # Setup: Upload a favicon first
    visit settings_edit_path
    attach_file "setting_favicon_original", Rails.root.join("test/fixtures/files/favicon_valid_512x512.png")
    click_on "Save Settings"
    assert_text "Settings Saved"
    @setting.reload
    assert @setting.favicon_original.attached?, "Setup for removal failed: Original not attached."
    # Check that a custom link is present (e.g. ico)
    assert_selector "link[rel='icon'][sizes='48x48'][href*='#{@setting.favicon_ico.filename.to_s}']", visible: false,
                      message: "Setup for removal failed: Custom ICO link not found."

    # Test Removal
    visit settings_edit_path # Re-visit to ensure form is fresh for the test action
    check "setting_remove_favicon" # This is the ID for the checkbox `form.check_box :remove_favicon`
    click_on "Save Settings"

    assert_text "Settings Saved"
    @setting.reload
    assert_not @setting.favicon_original.attached?, "Original favicon should be detached after removal."
    assert_not @setting.favicon_ico.attached?, "ICO variant should be detached after removal."
    # ... and so on for other variants

    # Assert preview is gone (assuming preview only shows if favicon_original is attached)
    # The filename used here should be the one that was just removed.
    assert_no_selector "img[src*='#{Regexp.escape('favicon_valid_512x512.png')}']"

    # Assert default favicons are back in <head>
    default_ico_path = ActionController::Base.helpers.asset_path('favicon.ico')
    assert_selector "link[rel='icon'][sizes='48x48'][href='#{default_ico_path}']", visible: false

    default_apple_path = ActionController::Base.helpers.asset_path('apple.png')
    assert_selector "link[rel='apple-touch-icon'][href='#{default_apple_path}']", visible: false
    
    default_16_path = ActionController::Base.helpers.asset_path('favicon-16x16.png')
    assert_selector "link[rel='icon'][type='image/png'][sizes='16x16'][href='#{default_16_path}']", visible: false
    
    default_32_path = ActionController::Base.helpers.asset_path('favicon-32x32.png')
    assert_selector "link[rel='icon'][type='image/png'][sizes='32x32'][href='#{default_32_path}']", visible: false
  end
end
