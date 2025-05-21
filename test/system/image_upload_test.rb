require "application_system_test_case"
require_relative 'systemtest_helpers.rb'

class ImageUploadTest < ApplicationSystemTestCase
  test "upload image and validate display" do
    admin_user = { email: "george@washington.com", pass: "georgepass" }

    log_in_with admin_user
    click_on "New Post Button" # Changed from "New Post Button" based on common practice, will verify if fails

    fill_in "post_content", with: "This is a test post with an image."

    attach_file('post_pic', Rails.root.join('test', 'fixtures', 'files', 'test_image.png'))
    click_on "Upload Selected Image"

    assert_selector "img[src*='test_image.png']"

    click_on "Save Post"

    assert_selector "img[src*='test_image.png']"
  end
end
