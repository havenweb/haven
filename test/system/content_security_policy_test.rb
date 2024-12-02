require "application_system_test_case"
require_relative 'systemtest_helpers.rb'

class ContentSecurityPolicyTest < ApplicationSystemTestCase
  test_users = {
    washington: {email: "george@washington.com", pass: "georgepass"}, # admin
    jackson: {email: "andrew@jackson.com", pass: "jacksonpass"},      # publisher
    lincoln: {email: "abraham@lincoln.com", pass: "lincolnpass"}     # subscriber
  }

  ## This test is also ensuring that the content security policy doesn't prevent
  ## the Javascript code which generates live previews from entered markdown
  test "editing a post generates a markdown preview" do
    log_in_with test_users[:jackson]
    click_on "New Post Button"
    m = "#{rand} Post Title"
    fill_in "post_content", with: "# #{m}"
    # Javascript preview creates <h1> tag with contents of `m`
    assert_selector "h1", text: m
    # finish and log out
    click_on "Save Post"
    click_on "Logout"
  end

end
