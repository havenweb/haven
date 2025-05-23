require "application_system_test_case"
require_relative 'systemtest_helpers.rb'

class MediaUploadTest < ApplicationSystemTestCase
  test "upload mp3 and validate display" do
    admin_user = { email: "george@washington.com", pass: "georgepass" }

    log_in_with admin_user
    click_on "New Post Button"

    fill_in "post_content", with: "This is a test post with an mp3 audio file."

    assert_no_selector "audio"
    attach_file('post_pic', Rails.root.join('test', 'fixtures', 'files', 'test_audio.mp3'))
    click_on "Upload Selected Image"

    assert_selector "audio"
    assert_selector "audio source[src*='test_audio.mp3']", visible: :all

    click_on "Save Post"

    assert_selector "audio"
    assert_selector "audio source[src*='test_audio.mp3']", visible: :all
    click_on "Logout"
  end

  test "upload mp4 and validate display" do
    admin_user = { email: "george@washington.com", pass: "georgepass" }

    log_in_with admin_user
    click_on "New Post Button"

    fill_in "post_content", with: "This is a test post with an mp4 video file."

    assert_no_selector "video"
    attach_file('post_pic', Rails.root.join('test', 'fixtures', 'files', 'test_video.mp4'))
    click_on "Upload Selected Image"

    assert_selector "video"
    assert_selector "video source[src*='test_video.mp4']", visible: :all

    click_on "Save Post"

    assert_selector "video"
    assert_selector "video source[src*='test_video.mp4']", visible: :all
    click_on "Logout"
  end

  test "upload mov and validate display" do
    admin_user = { email: "george@washington.com", pass: "georgepass" }

    log_in_with admin_user
    click_on "New Post Button"

    fill_in "post_content", with: "This is a test post with a mov video file."

    assert_no_selector "video"
    attach_file('post_pic', Rails.root.join('test', 'fixtures', 'files', 'test_video.mov'))
    click_on "Upload Selected Image"

    assert_selector "video"
    assert_selector "video source[src*='test_video.mov']", visible: :all

    click_on "Save Post"

    assert_selector "video"
    assert_selector "video source[src*='test_video.mov']", visible: :all
    click_on "Logout"
  end
end
