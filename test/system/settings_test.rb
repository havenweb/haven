require "application_system_test_case"
require_relative 'systemtest_helpers.rb'

class SettingsTest < ApplicationSystemTestCase
  test_users = {
    washington: {email: "george@washington.com", pass: "georgepass"} # admin
  }

  test "custom css overrides more specific app css" do
    my_admin = test_users[:washington]
    log_in_with my_admin

    visit settings_edit_path

    fill_in "setting[title]", with: "My Custom Title"

    # We will override the specific rule `h1.title` from app/assets/stylesheets/new.css
    # `new.css` has: `h1.title { font-size: 2.25rem; }`
    # We will provide a rule for just `h1` in the custom css. The controller code makes it `!important`,
    # so `h1` should override `h1.title`. Let's test this to be sure the `!important` part is working.
    fill_in "setting[css]", with: "h1 { font-size: 100px; }"
    click_on "Save Settings"

    assert_text "Settings Saved"

    assert_equal "100px", evaluate_script("window.getComputedStyle(arguments[0]).fontSize", find('h1.title'))
  end
end
