require File.join(Rails.root, "lib","haven_feed_entry.rb")

class UpdateFeedJob < ApplicationJob
  queue_as :default

  # Constants for feed entry keys
  ERROR_UNKNOWN = "Unknown Feed Type (not RSS or Atom)"
  ERROR_INVALID = "Invalid Feed"

  def perform(*feeds)
    # If a feed were to future-date an entry, then it might stay at the top
    # of the feed for a long time.  If a feed entry has a published time in
    # the future, we set the sort_date to today.
    latest_time = Time.zone.now # latest a new feed_entry can be
    earliest_time = nil
    if FeedEntry.count > 0
      # some feeds will publish updates late, for example, publishing an entry
      # on Jan 2 with a date of Jan 1.  To prevent these from getting lost in 
      # the feed, we keep track of the earliest time an entry can be on each
      # fetch.  It must be no earlier than one second after the most recent
      # entry.  This is the purpose of the `sort_date` field.
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
    feed.with_lock do
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
    end # release lock

    # fetch feed content
    return unless feed.last_update.nil? or feed.last_update < 10.minutes.ago
    feed.with_lock do
      entries = []
      begin
        entries = HavenFeedEntry.fetch_feed_content(feed.url)
        feed.fetch_succeeded!
        feed.last_update = DateTime.now
        feed.save
      rescue
        feed.fetch_failed!
      end
      entries.each {|e| e.date = Time.zone.now if e.date.nil? }
      # ensure that the newest entry is first in the array
      entries
       .sort_by{|e| e.date}
       .reverse
       .each_with_index do |entry, entry_index|
        title = entry.title
        link = entry.link
        published = entry.date
        sort_date = published
        unless earliest_time.nil?
          if (sort_date < earliest_time) and entry_index == 0
            sort_date = earliest_time
          end
        end
        unless latest_time.nil?
          if sort_date > latest_time
            sort_date = latest_time
          end
        end
        content = entry.content
        guid = entry.guid
        audio = entry.audio
        matching_entry = feed.feed_entries.find_by(guid: guid)
        record_data = {title: title, link: link, published: published, sort_date: sort_date, content: content, audio: audio, guid: guid}
        update_data = {title: title, link: link, audio: audio, content: content}
        if matching_entry.nil?
          feed.feed_entries.create!(record_data)
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
    cleanurl, auth_opts = HavenFeedEntry.parse_auth(feed_url)
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

end
