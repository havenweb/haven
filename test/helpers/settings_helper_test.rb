require 'test_helper'

class SettingsHelperTest < ActionView::TestCase
  include Rails.application.routes.url_helpers # For url_for

  setup do
    @setting = SettingsController.get_setting
    @setting.save! if @setting.new_record?

    # Ensure favicon_original is purged before each test for isolation
    @setting.favicon_original.purge if @setting.favicon_original.attached?

    # @dummy_file_blob is used to test successful variant generation.
    # Assumes 'favicon_valid_512x512.png' exists. If it's an empty placeholder,
    # Active Storage might still consider it 'variable?' if content_type is 'image/png'.
    # The actual image processing would fail later, but URL generation for variants might succeed.
    @dummy_file_blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join('test/fixtures/files/favicon_valid_512x512.png'), 'rb'),
      filename: 'favicon_valid_512x512.png',
      content_type: 'image/png'
    )
  end

  teardown do
    @dummy_file_blob.try(:purge)
    # Ensure favicon_original is purged after tests if anything was attached.
    @setting.favicon_original.purge if @setting.favicon_original.attached?
  end

  # --- Test for custom_favicon_ico_url ---
  test "custom_favicon_ico_url returns static path" do
    assert_equal '/favicon.ico', custom_favicon_ico_url
  end

  # --- Tests for custom_favicon_apple_touch_url ---
  test "custom_favicon_apple_touch_url returns variant URL when original is attached and variable" do
    @setting.favicon_original.attach(@dummy_file_blob)
    # Assuming @dummy_file_blob is processable by ActiveStorage for .variant
    expected_url = url_for(@setting.favicon_original.variant(resize_to_fill: [180, 180]))
    assert_equal expected_url, custom_favicon_apple_touch_url
  end

  test "custom_favicon_apple_touch_url returns default URL when original is not attached" do
    assert_equal ActionController::Base.helpers.asset_path('apple.png'), custom_favicon_apple_touch_url
  end

  test "custom_favicon_apple_touch_url returns default URL when original is attached but not variable" do
    non_image_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("this is not an image"),
      filename: 'not_an_image.txt',
      content_type: 'text/plain'
    )
    @setting.favicon_original.attach(non_image_blob)
    
    assert_equal ActionController::Base.helpers.asset_path('apple.png'), custom_favicon_apple_touch_url
    
    non_image_blob.purge # Clean up this specific blob
  end

  # --- Tests for custom_favicon_32x32_url ---
  test "custom_favicon_32x32_url returns variant URL when original is attached and variable" do
    @setting.favicon_original.attach(@dummy_file_blob)
    expected_url = url_for(@setting.favicon_original.variant(resize_to_fill: [32, 32]))
    assert_equal expected_url, custom_favicon_32x32_url
  end

  test "custom_favicon_32x32_url returns default URL when original is not attached" do
    assert_equal ActionController::Base.helpers.asset_path('favicon-32x32.png'), custom_favicon_32x32_url
  end

  test "custom_favicon_32x32_url returns default URL when original is attached but not variable" do
    non_image_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("this is not an image"),
      filename: 'not_an_image.txt',
      content_type: 'text/plain'
    )
    @setting.favicon_original.attach(non_image_blob)
    assert_equal ActionController::Base.helpers.asset_path('favicon-32x32.png'), custom_favicon_32x32_url
    non_image_blob.purge
  end
  
  # --- Tests for custom_favicon_16x16_url ---
  test "custom_favicon_16x16_url returns variant URL when original is attached and variable" do
    @setting.favicon_original.attach(@dummy_file_blob)
    expected_url = url_for(@setting.favicon_original.variant(resize_to_fill: [16, 16]))
    assert_equal expected_url, custom_favicon_16x16_url
  end

  test "custom_favicon_16x16_url returns default URL when original is not attached" do
    assert_equal ActionController::Base.helpers.asset_path('favicon-16x16.png'), custom_favicon_16x16_url
  end

  test "custom_favicon_16x16_url returns default URL when original is attached but not variable" do
    non_image_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("this is not an image"),
      filename: 'not_an_image.txt',
      content_type: 'text/plain'
    )
    @setting.favicon_original.attach(non_image_blob)
    assert_equal ActionController::Base.helpers.asset_path('favicon-16x16.png'), custom_favicon_16x16_url
    non_image_blob.purge
  end

  # --- Tests for custom_favicon_512x512_url ---
  test "custom_favicon_512x512_url returns variant URL when original is attached and variable" do
    @setting.favicon_original.attach(@dummy_file_blob)
    expected_url = url_for(@setting.favicon_original.variant(resize_to_fill: [512, 512]))
    assert_equal expected_url, custom_favicon_512x512_url
  end

  test "custom_favicon_512x512_url returns default URL when original is not attached" do
    assert_equal ActionController::Base.helpers.asset_path('512.png'), custom_favicon_512x512_url
  end

  test "custom_favicon_512x512_url returns default URL when original is attached but not variable" do
    non_image_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("this is not an image"),
      filename: 'not_an_image.txt',
      content_type: 'text/plain'
    )
    @setting.favicon_original.attach(non_image_blob)
    assert_equal ActionController::Base.helpers.asset_path('512.png'), custom_favicon_512x512_url
    non_image_blob.purge
  end
end
