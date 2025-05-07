require "application_system_test_case"
require_relative 'systemtest_helpers.rb'

class IframeTest < ApplicationSystemTestCase
  test_users = {
    washington: {email: "george@washington.com", pass: "georgepass"}, # admin
    jackson: {email: "andrew@jackson.com", pass: "jacksonpass"},      # publisher
    lincoln: {email: "abraham@lincoln.com", pass: "lincolnpass"}     # subscriber
  }

  test "live preview and saved posts do not render an iframe" do
    [test_users[:washington], test_users[:jackson]].each do |test_user|
      log_in_with test_user
      click_on "New Post Button"
      m = '<iframe src="https://havenweb.org/" ></iframe>'
      fill_in "post_content", with: m
      assert_selector "iframe", count: 1 # preview renders iframe
      click_on "Save Post"
      assert_selector "iframe", count: 1 # saved post renders iframe
      click_on "Logout"
    end
  end

end
