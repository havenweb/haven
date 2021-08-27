class UpdateFeedJob < ApplicationJob
  queue_as :default

  # Constants for feed entry keys
  ENTRY_TITLE = "title"
  FEED_TITLE = "feed"
  ENTRY_LINK = "link"
  ENTRY_DATE = "date"
  ENTRY_CONTENT = "content"
  ENTRY_GUID = "guid"

  ERROR_UNKNOWN = "Unknown Feed Type (not RSS or Atom)"
  ERROR_INVALID = "Invalid Feed"

  def perform(*feeds)
    if feeds.empty?
      Feed.find_each do |feed|
        update_feed(feed)
      end
    else
      feeds.each do |feed|
        update_feed(feed)
      end
    end
  end

  private

  def update_feed(feed)
    # update feed title if not yet set
    if feed.name.nil?
      begin
        feed.name = fetch_feed_title(feed.url)
        feed.save
      rescue
        # TODO: retry with RSS autodiscovery?
        feed.name = ERROR_INVALID
        feed.save
        return
      end
    end
    if ([ERROR_UNKNOWN, ERROR_INVALID].include? feed.name)
      feed.feed_invalid!
      return
    end

    # fetch feed content
    return unless feed.last_update.nil? or feed.last_update < 10.minutes.ago
    entries = []
    begin
      entries = fetch_feed_content(feed.url)
      feed.fetch_succeeded!
      feed.last_update = DateTime.now
      feed.save
    rescue
      feed.fetch_failed!
    end
    entries.each do |entry|
      title = entry[ENTRY_TITLE]
      link = entry[ENTRY_LINK]
      published = entry[ENTRY_DATE]
      content = entry[ENTRY_CONTENT]
      guid = entry[ENTRY_GUID]
      matching_entry = feed.feed_entries.find_by(guid: guid)
      record_data = {title: title, link: link, published: published, content: content, guid: guid}
      if matching_entry.nil?
        feed.feed_entries.create(record_data)
      else
        matching_entry.update(record_data)
      end
    end
    feed.fetch_succeeded!
    feed.last_update = DateTime.now
    feed.save
  end

  def fetch_feed_title(feed_url)
    cleanurl, auth_opts = parse_auth(feed_url)
    open(cleanurl, auth_opts) do |rss|
      feed = RSS::Parser.parse(rss)
      if (feed.feed_type == "rss")
        return feed.channel.title
      elsif (feed.feed_type == "atom")
        return feed.title.content
      else
        return "Unknown Feed Type (not RSS or Atom)"
      end
    end
  rescue => e
    STDERR.puts e.message
    return "Invalid Feed"
  end

  def fetch_feed_content(feed_url)
    entries = []
    cleanurl, auth_opts = parse_auth(feed_url)
    open(cleanurl, auth_opts) do |rss|
      feed = RSS::Parser.parse(rss)
      if (feed.feed_type == "rss")
        feed.items.each do |item|
          entry = {}
          entry[FEED_TITLE] = feed.channel.title
          entry[ENTRY_TITLE] = item.title
          entry[ENTRY_LINK] = item.link
          entry[ENTRY_DATE] = item.date
          entry[ENTRY_CONTENT] = item.description
          entry[ENTRY_CONTENT] = item.content_encoded if item.content_encoded
          entry[ENTRY_GUID] = item.guid.content
          entries << entry
        end
      elsif (feed.feed_type == "atom")
        feed.entries.each do |item|
          entry = {}
          entry[FEED_TITLE] = feed.title.content
          entry[ENTRY_TITLE] = item.title.content
          entry[ENTRY_LINK] = item.link.href
          entry[ENTRY_DATE] = item.published
          entry[ENTRY_CONTENT] = item.content.to_s
          entry[ENTRY_GUID] = item.id
          entries << entry
        end
      end
    end
    entries
  end

  ## TODO: This also exists in app/controllers/feeds_controller.rb
  def parse_auth(full_url)
    scheme, rest = full_url.split("://",2)
    opts = {}
    if (rest.include?(":") and rest.include?("@")) # scheme://user:pass@url...
      user, rest = rest.split(":",2)
      pass, rest = rest.split("@",2)
      opts[:http_basic_authentication] = [user,pass]
      return ["#{scheme}://#{rest}", opts]
    else
      return [full_url, opts]
    end
  end
end
