require "application_system_test_case"
require_relative 'systemtest_helpers.rb'

class PasswordResetTest < ApplicationSystemTestCase
  test_users = {
    washington: {email: "george@washington.com", pass: "georgepass"},
    jackson: {email: "andrew@jackson.com", pass: "jacksonpass"}
  }

  test "magic link changes when admin resets user password" do
    my_admin = test_users[:washington]
    my_user = test_users[:jackson]

    my_user_record = User.find_by(email: my_user[:email])
    LoginLink.generate(my_user_record) if my_user_record.login_links.empty?
    old_link = my_user_record.login_links.last
    old_token = old_link.token

    log_in_with my_admin
    click_on "Users"

    # Click reset password for Jackson
    within("tr", text: "andrew@jackson.com") do
      click_on "Reset Password"
    end

    assert_text "User successfully updated"

    click_on "Logout"

    # Try logging in with the old token
    visit login_link_path(token: old_token)

    assert_text "Invalid token"
  end

  test "magic link changes when user changes password" do
    my_user = test_users[:jackson]
    log_in_with my_user

    # Generate a login link if it doesn't exist
    my_user_record = User.find_by(email: my_user[:email])
    LoginLink.generate(my_user_record) if my_user_record.login_links.empty?
    old_link = my_user_record.login_links.last
    old_token = old_link.token

    click_on "Account"

    # Target the current password specifically for the password change section
    within(all("form")[1]) do
      fill_in "Password", with: "newjacksonpass"
      fill_in "Password confirmation", with: "newjacksonpass"
      fill_in "Current password", with: "jacksonpass"
      click_on "Change Password"
    end

    assert_text "Your account has been updated successfully."

    # Try logging in with the old token
    click_on "Logout"
    visit login_link_path(token: old_token)

    assert_text "Invalid token"
  end
end
