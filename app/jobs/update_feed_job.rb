class UpdateFeedJob < ApplicationJob
  queue_as :default

  # Constants for feed entry keys
  ENTRY_TITLE = "title"
  FEED_TITLE = "feed"
  ENTRY_LINK = "link"
  ENTRY_DATE = "date"
  ENTRY_CONTENT = "content"
  ENTRY_GUID = "guid"
  ENTRY_AUDIO = "audio"

  ERROR_UNKNOWN = "Unknown Feed Type (not RSS or Atom)"
  ERROR_INVALID = "Invalid Feed"

  def perform(*feeds)
    latest_time = Time.zone.now # latest a new feed_entry can be
    earliest_time = nil
    if FeedEntry.count > 0
      # some feeds will publish updates late, for example, publishing an entry
      # on Jan 2 with a date of Jan 1.  To prevent these from getting lost in 
      # the feed, we keep track of the earliest time an entry can be on each
      # fetch.  It must be no earlier than one second after the most recent
      # entry.  This is the sole purpose of the `sort_date` field.
      earliest_time = FeedEntry.order(sort_date: :desc).first.sort_date + 1
    end
    if feeds.empty? # updating all feeds, enforce sort_date restrictions
      Feed.find_each do |feed|
        update_feed(feed, earliest_time, latest_time)
      end
    else # updating a single feed on creation, allow older sort_dates
      feeds.each do |feed|
        update_feed(feed, nil, latest_time)
      end
    end
  end

  private

  def truncate_feed(feed, max_count)
    entries = feed.feed_entries.order(sort_date: :desc).page(2).per(max_count)
    entries.each do |e|
      e.destroy!
    end
  rescue
    puts "Error truncating feed: #{feed.name}"
  end

  def update_feed(feed, earliest_time, latest_time)
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
    feed.with_lock do
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
        if published.nil?
          published = Time.zone.now
        end
        sort_date = published
        unless earliest_time.nil?
          if sort_date < earliest_time
            sort_date = earliest_time
          end
        end
        unless latest_time.nil?
          if sort_date > latest_time
            sort_date = latest_time
          end
        end
        content = entry[ENTRY_CONTENT]
        guid = entry[ENTRY_GUID]
        audio = entry[ENTRY_AUDIO]
        matching_entry = feed.feed_entries.find_by(guid: guid)
        record_data = {title: title, link: link, published: published, sort_date: sort_date, content: content, audio: audio, guid: guid}
        update_data = {title: title, link: link, audio: audio, content: content}
        if matching_entry.nil?
          feed.feed_entries.create(record_data)
        else
          matching_entry.update(update_data)
        end
      end
      feed.fetch_succeeded!
      feed.last_update = DateTime.now
      feed.save
      # truncate_feed(feed, 100)
    end # release lock
  end

  def fetch_feed_title(feed_url)
    cleanurl, auth_opts = parse_auth(feed_url)
    URI.open(cleanurl, auth_opts) do |rss|
      feed = RSS::Parser.parse(rss, validate: false)
      if (feed.feed_type == "rss")
        return feed.channel.title
      elsif (feed.feed_type == "atom")
        return feed.title.content
      else
        return "Unknown Feed Type (not RSS or Atom)"
      end
    end
  rescue => e
    logger.error "ERROR when fetching feed #{feed_url} #{e.class} #{e.message}"
    return "Invalid Feed"
  end

  def fetch_feed_content(feed_url)
    entries = []
    cleanurl, auth_opts = parse_auth(feed_url)
    URI.open(cleanurl, auth_opts) do |rss|
      feed = RSS::Parser.parse(rss, validate: false)
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
          if item.enclosure && item.enclosure.type == "audio/mpeg"
            entry[ENTRY_AUDIO] = item.enclosure.url
          else
            entry[ENTRY_AUDIO] = nil
          end
          entries << entry
        end
      elsif (feed.feed_type == "atom")
        feed.entries.each do |item|
          entry = {}
          entry[FEED_TITLE] = feed.title.content
          entry[ENTRY_TITLE] = item.title.content
          entry[ENTRY_LINK] = item.link.href
          begin
            entry[ENTRY_DATE] = item.published.content
          rescue
            entry[ENTRY_DATE] = item.published
          end
          entry[ENTRY_CONTENT] = CGI.unescapeHTML(item.content.to_s)
          entry[ENTRY_GUID] = item.id.to_s
          entry[ENTRY_AUDIO] = nil # TODO podcast support for Atom feeds
          entries << entry
        end
      end
    end
    entries
  end

  def parse_auth(full_url)
    scheme, rest = full_url.split("://",2)
    opts = {}
    opts["User-Agent"] = "haven"
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
