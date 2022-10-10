require "application_system_test_case"

class ActionsTest < ApplicationSystemTestCase
   test_users = {washington: {email: "george@washington.com", pass: "georgepass"},
                 lincoln: {email: "abraham@lincoln.com", pass: "lincolnpass"}}

   def log_in_with(u) # u is a hash with fields email: and pass:
     visit root_url
     fill_in "user_email", with: u[:email]
     fill_in "user_password", with: u[:pass]
     click_on "Log in"
   end

   test "visiting the index" do
     visit root_url
     assert_selector "a", text: "Home"
   end

   test "logged in users can see posts" do
     test_users.each_value do |u|
       log_in_with u
       assert_text "MyTextOne" # From Fixture
       assert_text "MyTextTwo" # From Fixture
       click_on "Logout"
     end
   end

   test "logged in admin can add and view posts" do
     log_in_with test_users[:washington]
     click_on "New Post Button"
     m = "I cannot tell a lie!"
     fill_in "post_content", with: m
     click_on "Save Post"
     assert_text m # page previw shows post content
     click_on "Home"
     assert_text m # recent posts page also shows content of new post"
   end
end
