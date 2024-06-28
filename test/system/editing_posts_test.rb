require "application_system_test_case"
require_relative 'systemtest_helpers.rb'

class EditingPostsTest < ApplicationSystemTestCase
  test_users = {
    washington: {email: "george@washington.com", pass: "georgepass"}, # admin
    jackson: {email: "andrew@jackson.com", pass: "jacksonpass"},      # publisher
    lincoln: {email: "abraham@lincoln.com", pass: "lincolnpass"}     # subscriber
  }

  test "publisher and admin can edit their own posts" do
    [test_users[:washington], test_users[:jackson]].each do |test_user|
      log_in_with test_user
      click_on "New Post Button"
      m = "#{rand} I cannot tell a lie!"
      fill_in "post_content", with: m
      click_on "Save Post"
      assert_text m # page previw shows post content
      click_on "Home"
      assert_text m # recent posts page also shows content of new post"
      ## Find edit button
      ## click edit button
      ## change post content
      ## validate new post content is saved
      click_on "Logout"
    end
  end

  test "admin editing a post doesn't change ownership of the post" do
    log_in_with test_users[:jackson] #publisher
    click_on "New Post Button"
    m = "#{rand} I cannot tell a lie"
    fill_in "post_content", with: m
    click_on "Save Post"
    assert_text m # page previw shows post content
    post_url = current_url
    click_on "Logout"

    log_in_with test_users[:washington] #admin
      visit post_url
      click_on "Edit"
      m2 = "#{rand} what a lie"
      fill_in "post_content", with: m2
      click_on "Save Post"
      assert_text m2
    click_on "Logout"

    log_in_with test_users[:jackson] #publisher
      visit post_url
      click_on "Edit"
      m3 = "#{rand} no lies here"
      fill_in "post_content", with: m3
      click_on "Save Post"
      assert_text m3
    click_on "Logout"

  end
end
