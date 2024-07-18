require "application_system_test_case"
require_relative 'systemtest_helpers.rb'

class AccountManagementTest < ApplicationSystemTestCase
  test_users = {
    washington: {email: "george@washington.com", pass: "georgepass"}, # admin
    jackson: {email: "andrew@jackson.com", pass: "jacksonpass"},      # publisher
    lincoln: {email: "abraham@lincoln.com", pass: "lincolnpass"}     # subscriber
  }

  test "admin can create a user" do
    my_admin = test_users[:washington]
    log_in_with my_admin
    click_on "Users"
    click_on "New User"
    new_name = (rand*10000).to_i.to_s
    new_email = "#{new_name}@example.com"
    fill_in "Email", with: new_email
    fill_in "Name", with: new_name
    click_on "Create User"
    assert_text "User successfully created"
    assert_text new_email

    new_password = ""
    page.body.each_line do |line|
      if line.include? "Password:"
        new_password = line.split("<strong>Password:</strong> ", 2).last.split("<br>").first
      end
    end

    click_on "Logout"
    fill_in "Email", with: new_email
    fill_in "Password", with: new_password
    click_on "Log in"
    click_on "Account"
    accept_confirm do
      click_on "Delete my account"
    end

    fill_in "Email", with: new_email
    fill_in "Password", with: new_password
    click_on "Log in"
    assert_text "Invalid" ## can no longer login because account deleted
  end

end
