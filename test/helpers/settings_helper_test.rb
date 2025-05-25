require 'test_helper'

class SettingsHelperTest < ActionView::TestCase
  include Rails.application.routes.url_helpers # For url_for

  setup do
    @setting = SettingsController.get_setting
    @setting.save! if @setting.new_record?

    # Ensure favicon_original is purged before each test for isolation
    @setting.favicon_original.purge if @setting.favicon_original.attached?

    @dummy_file_blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join('test/fixtures/files/favicon_valid_512x512.png'), 'rb'),
      filename: 'favicon_valid_512x512.png',
      content_type: 'image/png'
    )
  end

  teardown do
    @dummy_file_blob.try(:purge)
    @setting.favicon_original.purge if @setting.favicon_original.attached?
  end

  # --- Test for custom_favicon_ico_url ---
  test "custom_favicon_ico_url returns static path" do
    assert_equal '/favicon.ico', custom_favicon_ico_url
  end

  # --- Tests for custom_favicon_apple_touch_url ---
  test "custom_favicon_apple_touch_url returns variant URL when original is attached and variable" do
    @setting.favicon_original.attach(@dummy_file_blob)
    expected_url = url_for(@setting.favicon_original.variant(resize_to_fill: [180, 180]))
    assert_equal expected_url, custom_favicon_apple_touch_url
  end

  test "custom_favicon_apple_touch_url returns nil when original is not attached" do
    assert_nil custom_favicon_apple_touch_url
  end

  test "custom_favicon_apple_touch_url returns nil when original is attached but not variable" do
    non_image_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("this is not an image"),
      filename: 'not_an_image.txt',
      content_type: 'text/plain'
    )
    @setting.favicon_original.attach(non_image_blob)
    assert_nil custom_favicon_apple_touch_url
    non_image_blob.purge # Clean up this specific blob
  end

  # --- Tests for custom_favicon_32x32_url ---
  test "custom_favicon_32x32_url returns variant URL when original is attached and variable" do
    @setting.favicon_original.attach(@dummy_file_blob)
    expected_url = url_for(@setting.favicon_original.variant(resize_to_fill: [32, 32]))
    assert_equal expected_url, custom_favicon_32x32_url
  end

  test "custom_favicon_32x32_url returns nil when original is not attached" do
    assert_nil custom_favicon_32x32_url
  end

  test "custom_favicon_32x32_url returns nil when original is attached but not variable" do
    non_image_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("this is not an image"),
      filename: 'not_an_image.txt',
      content_type: 'text/plain'
    )
    @setting.favicon_original.attach(non_image_blob)
    assert_nil custom_favicon_32x32_url
    non_image_blob.purge
  end
  
  # --- Tests for custom_favicon_16x16_url ---
  test "custom_favicon_16x16_url returns variant URL when original is attached and variable" do
    @setting.favicon_original.attach(@dummy_file_blob)
    expected_url = url_for(@setting.favicon_original.variant(resize_to_fill: [16, 16]))
    assert_equal expected_url, custom_favicon_16x16_url
  end

  test "custom_favicon_16x16_url returns nil when original is not attached" do
    assert_nil custom_favicon_16x16_url
  end

  test "custom_favicon_16x16_url returns nil when original is attached but not variable" do
    non_image_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("this is not an image"),
      filename: 'not_an_image.txt',
      content_type: 'text/plain'
    )
    @setting.favicon_original.attach(non_image_blob)
    assert_nil custom_favicon_16x16_url
    non_image_blob.purge
  end

  # --- Tests for custom_favicon_512x512_url ---
  test "custom_favicon_512x512_url returns variant URL when original is attached and variable" do
    @setting.favicon_original.attach(@dummy_file_blob)
    expected_url = url_for(@setting.favicon_original.variant(resize_to_fill: [512, 512]))
    assert_equal expected_url, custom_favicon_512x512_url
  end

  test "custom_favicon_512x512_url returns nil when original is not attached" do
    assert_nil custom_favicon_512x512_url
  end

  test "custom_favicon_512x512_url returns nil when original is attached but not variable" do
    non_image_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("this is not an image"),
      filename: 'not_an_image.txt',
      content_type: 'text/plain'
    )
    @setting.favicon_original.attach(non_image_blob)
    assert_nil custom_favicon_512x512_url
    non_image_blob.purge
  end
end
