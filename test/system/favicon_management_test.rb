require "application_system_test_case"
require 'fileutils' # For FileUtils.touch

class FaviconManagementTest < ApplicationSystemTestCase
  include Rails.application.routes.url_helpers # For url_for

  setup do
    @admin_user = users(:washington) # Changed from :admin_user to :washington
    login_as @admin_user, scope: :user 
    @setting = SettingsController.get_setting
    @setting.save! if @setting.new_record?

    # Ensure a default public/favicon.ico exists for comparison in tests
    @default_public_ico_path = Rails.root.join('public', 'favicon.ico')
    unless File.exist?(@default_public_ico_path)
      FileUtils.mkdir_p(Rails.root.join('public'))
      File.write(@default_public_ico_path, "dummy default public ico content")
    end
    @default_public_ico_content = File.binread(@default_public_ico_path)
  end

  test "uploading a valid favicon and seeing it applied" do
    visit settings_edit_path

    # Detach any existing favicons
    @setting.favicon_original.purge if @setting.favicon_original.attached?
    @setting.save!
    visit settings_edit_path 

    attach_file "setting_favicon_original", Rails.root.join("test/fixtures/files/favicon_valid_512x512.png")
    click_on "Save Settings"

    assert_text "Settings Saved"
    @setting.reload 
    assert @setting.favicon_original.attached?, "Favicon original should be attached after save."


    # Check for preview image
    assert_selector "img[src*='#{Regexp.escape(@setting.favicon_original.filename.to_s)}']"

    # Check <link> tags in head
    assert_selector "link[rel='icon'][sizes='48x48'][href='/favicon.ico']", visible: false
    
    # For dynamically generated variants, we need the blob to be analyzed if it's a real image.
    # If 'favicon_valid_512x512.png' is a placeholder, .variant might still generate a URL
    # but the image itself wouldn't be valid.
    if @setting.favicon_original.variable? # Check if it's processable
      apple_touch_variant_url = url_for(@setting.favicon_original.variant(resize_to_fill: [180, 180]))
      assert_selector "link[rel='apple-touch-icon'][href='#{apple_touch_variant_url}']", visible: false

      png_16_variant_url = url_for(@setting.favicon_original.variant(resize_to_fill: [16, 16]))
      assert_selector "link[rel='icon'][type='image/png'][sizes='16x16'][href='#{png_16_variant_url}']", visible: false

      png_32_variant_url = url_for(@setting.favicon_original.variant(resize_to_fill: [32, 32]))
      assert_selector "link[rel='icon'][type='image/png'][sizes='32x32'][href='#{png_32_variant_url}']", visible: false
    else
      # If not variable (e.g. placeholder wasn't image-like enough for Active Storage to analyze)
      # then these links should point to their defaults.
      assert_selector "link[rel='apple-touch-icon'][href='#{ActionController::Base.helpers.asset_path('apple.png')}']", visible: false
      assert_selector "link[rel='icon'][type='image/png'][sizes='16x16'][href='#{ActionController::Base.helpers.asset_path('favicon-16x16.png')}']", visible: false
      assert_selector "link[rel='icon'][type='image/png'][sizes='32x32'][href='#{ActionController::Base.helpers.asset_path('favicon-32x32.png')}']", visible: false
    end
  end

  test "attempting to upload an invalid favicon (too small)" do
    visit settings_edit_path
    @setting.favicon_original.purge if @setting.favicon_original.attached?
    @setting.save!
    visit settings_edit_path

    attach_file "setting_favicon_original", Rails.root.join("test/fixtures/files/favicon_invalid_200x200.png")
    click_on "Save Settings"

    assert_text "Favicon must be square and at least 512x512 pixels."
    @setting.reload
    assert_not @setting.favicon_original.attached?

    # Assert that the default favicon links are still in place
    assert_selector "link[rel='icon'][sizes='48x48'][href='/favicon.ico']", visible: false # Will serve default
    
    # For conditionally rendered PNG links, assert they are NOT present
    assert_no_selector "link[rel='apple-touch-icon']", visible: false
    assert_no_selector "link[type='image/png'][sizes='16x16']", visible: false
    assert_no_selector "link[type='image/png'][sizes='32x32']", visible: false
  end

  test "removing a custom favicon" do
    visit settings_edit_path
    attach_file "setting_favicon_original", Rails.root.join("test/fixtures/files/favicon_valid_512x512.png")
    click_on "Save Settings"
    assert_text "Settings Saved"
    @setting.reload
    assert @setting.favicon_original.attached?, "Setup for removal failed: Original not attached."

    visit settings_edit_path 
    check "setting_remove_favicon" 
    click_on "Save Settings"

    assert_text "Settings Saved"
    @setting.reload
    assert_not @setting.favicon_original.attached?, "Original favicon should be detached after removal."
    assert_no_selector "img[src*='#{Regexp.escape('favicon_valid_512x512.png')}']"

    # Assert default favicons are back in <head>
    assert_selector "link[rel='icon'][sizes='48x48'][href='/favicon.ico']", visible: false # Will serve default

    # For conditionally rendered PNG links, assert they are NOT present after removal
    assert_no_selector "link[rel='apple-touch-icon']", visible: false
    assert_no_selector "link[type='image/png'][sizes='16x16']", visible: false
    assert_no_selector "link[type='image/png'][sizes='32x32']", visible: false
  end

  test "visiting /favicon.ico serves custom ico if set, otherwise default" do
    # Scenario 1: Custom Favicon
    visit settings_edit_path
    # Purge if any to ensure clean state for custom upload
    @setting.favicon_original.purge if @setting.favicon_original.attached?
    @setting.save!
    visit settings_edit_path

    attach_file "setting_favicon_original", Rails.root.join("test/fixtures/files/favicon_valid_512x512.png")
    click_on "Save Settings"
    assert_text "Settings Saved"
    @setting.reload
    assert @setting.favicon_original.attached?, "Custom favicon should be attached for scenario 1"

    visit '/favicon.ico'
    assert_equal 'image/vnd.microsoft.icon', page.response_headers['Content-Type']
    assert_not_empty page.body 
    # If favicon_valid_512x512.png is a placeholder, the generated ICO might be very small or invalid.
    # A more robust check (if it was a real image) would be size or specific bytes.
    # Here, we primarily check it's not the default public/favicon.ico's dummy content.
    assert_not_equal @default_public_ico_content, page.body, "Served default public ICO content instead of custom one."

    # Scenario 2: Default Favicon
    visit settings_edit_path
    check "setting_remove_favicon" 
    click_on "Save Settings"
    assert_text "Settings Saved"
    @setting.reload
    assert_not @setting.favicon_original.attached?, "Custom favicon should be removed for scenario 2"

    visit '/favicon.ico'
    assert_equal 'image/vnd.microsoft.icon', page.response_headers['Content-Type']
    assert_equal @default_public_ico_content, page.body, "Did not serve default public ICO content."
  end
end
