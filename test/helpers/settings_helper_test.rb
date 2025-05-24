require 'test_helper'

class SettingsHelperTest < ActionView::TestCase # Use ActionView::TestCase for helper tests
  include Rails.application.routes.url_helpers # For url_for used by Active Storage

  setup do
    @setting = SettingsController.get_setting
    @setting.save! if @setting.new_record? # Ensure it's persisted for attachments

    # Ensure all potential favicons are purged before each test for isolation
    @setting.favicon_original.purge if @setting.favicon_original.attached?
    @setting.favicon_ico.purge if @setting.favicon_ico.attached?
    @setting.favicon_apple_touch.purge if @setting.favicon_apple_touch.attached?
    @setting.favicon_32x32.purge if @setting.favicon_32x32.attached?
    @setting.favicon_16x16.purge if @setting.favicon_16x16.attached?
    @setting.favicon_512x512.purge if @setting.favicon_512x512.attached?

    # A generic small file to attach for testing URL generation.
    # Assumes 'favicon_valid_512x512.png' exists from previous test setups.
    # This file must exist at 'test/fixtures/files/favicon_valid_512x512.png'
    @dummy_file_blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join('test/fixtures/files/favicon_valid_512x512.png'), 'rb'),
      filename: 'favicon_valid_512x512.png',
      content_type: 'image/png'
    )
  end

  teardown do
    # Clean up blobs created by tests to avoid test leakage
    @dummy_file_blob.try(:purge)
  end

  # --- Tests for custom_favicon_ico_url ---
  test "custom_favicon_ico_url returns custom URL when attached" do
    @setting.favicon_ico.attach(@dummy_file_blob)
    assert_includes custom_favicon_ico_url, @dummy_file_blob.filename.to_s
  end

  test "custom_favicon_ico_url returns default URL when not attached" do
    assert_equal ActionController::Base.helpers.asset_path('favicon.ico'), custom_favicon_ico_url
  end

  # --- Tests for custom_favicon_apple_touch_url ---
  test "custom_favicon_apple_touch_url returns custom URL when attached" do
    @setting.favicon_apple_touch.attach(@dummy_file_blob)
    assert_includes custom_favicon_apple_touch_url, @dummy_file_blob.filename.to_s
  end

  test "custom_favicon_apple_touch_url returns default URL when not attached" do
    assert_equal ActionController::Base.helpers.asset_path('apple.png'), custom_favicon_apple_touch_url
  end

  # --- Tests for custom_favicon_32x32_url ---
  test "custom_favicon_32x32_url returns custom URL when attached" do
    @setting.favicon_32x32.attach(@dummy_file_blob)
    assert_includes custom_favicon_32x32_url, @dummy_file_blob.filename.to_s
  end

  test "custom_favicon_32x32_url returns default URL when not attached" do
    assert_equal ActionController::Base.helpers.asset_path('favicon-32x32.png'), custom_favicon_32x32_url
  end
  
  # --- Tests for custom_favicon_16x16_url ---
  test "custom_favicon_16x16_url returns custom URL when attached" do
    @setting.favicon_16x16.attach(@dummy_file_blob)
    assert_includes custom_favicon_16x16_url, @dummy_file_blob.filename.to_s
  end

  test "custom_favicon_16x16_url returns default URL when not attached" do
    assert_equal ActionController::Base.helpers.asset_path('favicon-16x16.png'), custom_favicon_16x16_url
  end

  # --- Tests for custom_favicon_512x512_url ---
  test "custom_favicon_512x512_url returns custom URL when attached" do
    @setting.favicon_512x512.attach(@dummy_file_blob)
    assert_includes custom_favicon_512x512_url, @dummy_file_blob.filename.to_s
  end

  test "custom_favicon_512x512_url returns default URL when not attached" do
    assert_equal ActionController::Base.helpers.asset_path('512.png'), custom_favicon_512x512_url
  end
end
