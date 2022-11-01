require "application_system_test_case"
require_relative 'systemtest_helpers.rb'

class ActionsTest < ApplicationSystemTestCase
  test_users = {washington: {email: "george@washington.com", pass: "georgepass"}, # admin
                jackson: {email: "andrew@jackson.com", pass: "jacksonpass"},      # publisher
                lincoln: {email: "abraham@lincoln.com", pass: "lincolnpass"}}     # subscriber

  test "visiting the index" do
    visit root_url
    assert_selector "a", text: "Home"
  end

  test "non-user cannot log in" do 
    log_in_with({user: "notmy@email.com", pass: "notapassword"})
    assert_text "Invalid Email or password."
  end

  test "logged in users can see posts" do
    test_users.each_value do |u|
      log_in_with u
      assert_text "MyTextOne" # From Fixture
      assert_text "MyTextTwo" # From Fixture
      click_on "Logout"
    end
  end

  test "logged in admin and publisher can add and view posts" do
    [test_users[:washington], test_users[:jackson]].each do |test_user|
      log_in_with test_user
      click_on "New Post Button"
      m = "#{rand} I cannot tell a lie!"
      fill_in "post_content", with: m
      click_on "Save Post"
      assert_text m # page previw shows post content
      click_on "Home"
      assert_text m # recent posts page also shows content of new post"
      click_on "Logout"
      #subscriber can see the new post too
      log_in_with test_users[:lincoln]
      assert_text m
      click_on "Logout"
    end
  end

  test "admin can create a new user who can log in" do
    log_in_with test_users[:washington]
    click_on "Users"
    click_on "New User"
    email = "martha@washington.com"
    fill_in "Email", with: email
    fill_in "Name", with: "Martha Washington"
    click_on "Create User"
    ## Extract password
    password = ""
    content = page.find('body').text
    content.split("\n").each do |chunk|
      if chunk.include? "Password:"
        password = chunk.split(":").last.strip
      end
    end
    ## Try it
    click_on "Logout"
    log_in_with({email: email, pass: password})
    assert_text "MyTextOne" # From Fixture
    assert_text "MyTextTwo" # From Fixture
    click_on "Logout"
  end

  test "subscriber and publisher cannot modify things" do
    [test_users[:lincoln], test_users[:jackson]].each do |test_user|
      log_in_with test_user
      visit new_user_url #admin user creation
      assert page.has_no_link? "Users"
      assert page.has_no_link? "Settings"
      visit settings_edit_url
      assert page.has_no_link? "Users"
      assert page.has_no_link? "Settings"
      click_on "Logout"
    end
  end
end
