require "application_system_test_case"
require_relative 'systemtest_helpers.rb'

class ActionsTest < ApplicationSystemTestCase
test_users = {washington: {email: "george@washington.com", pass: "georgepass"}, # admin
                jackson: {email: "andrew@jackson.com", pass: "jacksonpass"},      # publisher
                lincoln: {email: "abraham@lincoln.com", pass: "lincolnpass"}}     # subscriber

  test "admin can add a feed and view it" do
    [ # test only works with one remote feed at a time
     {url: "havenweb.org", title: "Haven Blog"},
#     {url: "xkcd.com", title: "xkcd.com"}
    ].each do |feed_source|
      log_in_with test_users[:washington]
      assert_text "Read"
      click_on "Read"
      assert_no_text feed_source[:title] # feed not added yet
      assert_no_selector "img"
      click_button "Manage Feeds"
      fill_in "feed_url", with: feed_source[:url]
      click_on "Add Feed"
      assert_text "You've added"
      assert_text "to your feeds"
      assert_text feed_source[:title]
      click_on feed_source[:title] # view just that feed
      assert_text feed_source[:title]
      assert_selector "img"
      click_on "Read" # reader view for all feeds
      assert_text feed_source[:title]
      assert_selector "img"
      click_on "Logout"
    end
  end

  test "non-admins cannot view a feed" do
    [:jackson, :lincoln].each do |u|
      log_in_with test_users[u]
      assert_no_text "Read"
      visit read_url
      assert_no_text "Manage Feed"
      click_on "Logout"
    end
  end

  test "feed pagination is consistent" do
    # TODO
    # login
    # subscribe to a feed
    # view the first page (/read)
    # note the last feed entry (call it old_last)
    # subscribe to another feed that only has one entry, newer than the others
    # click to the second page
    # assert that old_last is not present
    # click to the first page
    # assert that old_last is present
    # visit /read directy
    # assert that old_last is not present
    # click to the second page
    # assert that old_last is present
    assert true
  end
end
