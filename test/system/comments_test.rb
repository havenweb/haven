require "application_system_test_case"
require_relative 'systemtest_helpers.rb'


class ActionsTest < ApplicationSystemTestCase

  test_users = {washington: {email: "george@washington.com", pass: "georgepass"}, # admin
                jackson: {email: "andrew@jackson.com", pass: "jacksonpass"},      # publisher
                lincoln: {email: "abraham@lincoln.com", pass: "lincolnpass"}}     # subscriber

  test "subscriber can leave a comment on a post" do
    log_in_with test_users[:washington]
    # enable comments
    click_on "Settings"
    check "setting[comments]"
    click_on "Save Settings"
    click_on "Home"
    assert page.has_button? "Post Comment"
    # add a post
    m = "#{rand} I cannot tell a lie!"
    make_post(m)
    click_on "Logout"
    # subscriber makes a comment
    log_in_with test_users[:lincoln]
    c = "#{rand} nice post!"
    fill_in "comment_body", with: c, match: :first
    click_on "Post Comment", match: :first
    assert_text c
    click_on "Logout"
    # admin can see comment
    log_in_with test_users[:washington]
    assert_text c
  end

end
