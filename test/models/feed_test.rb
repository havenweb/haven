require 'test_helper'
require File.join(Rails.root, "lib","haven_feed_entry.rb") 

class FeedTest < ActiveSupport::TestCase
  test "should allow new feed entries to be saved to a feed" do
    user = User.find(1)
    (1..10).each do |i|
      feed = user.feeds.create!({url:"https://feed#{i}.url/rss"})
      feed.with_lock do
        (1..10).each do |j|
          title = "Post Title #{j}"
          link = "https://feed#{i}.url/#{j}.html"
          published = Time.zone.now
          sort_date = published
          content = "My Post Number #{j}"
          audio = nil
          guid = link
          record_data = {title: title, link: link, published: published, sort_date: sort_date, content: content, audio: audio, guid: guid}
          entry = feed.feed_entries.create!(record_data)
          assert_not_nil entry.published
        end
      end # release lock
    end
  rescue => e
    assert false, "Error saving feed: #{e}"
  end

  test "should_accept_feed_entries_from_an_rss_feed" do
    user = User.find(1)
    feed = user.feeds.create!({url:"https://havenweb.org/feed.xml"})
    atom_file = File.open(File.join(Rails.root,"test","fixtures","files","haven-rss.xml"))
    entries = HavenFeedEntry.parse_feed_content(atom_file)
    entries.each do |e|
      record_data = {title: e.title, link: e.link, published: e.date, sort_date: e.date, content: e.content, audio: e.audio, guid: e.guid}
      table_entry = feed.feed_entries.create!(record_data)
      assert_not_nil table_entry.published
    end
  end

  test "should_accept_feed_entries_from_an_atom_feed" do
    user = User.find(1)
    {
      "https://astralcodexten.substack.com/feed" => "substack-atom.xml",
      "https://xkcd.com/atom.xml" => "xkcd-atom.xml"
    }.each do |feed_url, feed_file|
      feed = user.feeds.create!({url:feed_url})
      atom_file = File.open(File.join(Rails.root,"test","fixtures","files",feed_file))
      entries = HavenFeedEntry.parse_feed_content(atom_file)
      entries.each do |e|
        record_data = {title: e.title, link: e.link, published: e.date, sort_date: e.date, content: e.content, audio: e.audio, guid: e.guid}
        table_entry = feed.feed_entries.create!(record_data)
        assert_not_nil table_entry.published
      end
    end
  end
end
