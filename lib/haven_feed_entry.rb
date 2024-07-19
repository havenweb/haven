require 'cgi'

class HavenFeedEntry
  attr_reader :feed_title, :title, :link, :date, :content, :guid, :audio

  ## feed is return from RSS::Parser.parse()
  ## item is element from feed.items (rss) or feed.entries (atom)
  def initialize(feed, item)
    if (feed.feed_type == "rss")
      @feed_title = feed.channel.title
      @title = item.title
      @link = item.link
      @date = parse_time(item.date)
      @content = item.description
      @content = item.content_encoded if item.content_encoded
      @guid = item.guid.content
      @audio = nil
      if item.enclosure
        if item.enclosure.type == "audio/mpeg"
          @audio = item.enclosure.url
        elsif item.enclosure.type.start_with? "image/" # If there is an image in the enclosure
          unless @content.include? "<img " # and no images in the content
            # then include the enclosure image
            @content = "<img src=\"#{item.enclosure.url}\" /><br/>" + @content
          end
        end
      end
    elsif (feed.feed_type == "atom")
      @feed_title = feed.title.content
      @title = item.title.content
      @link = item.link.href
      if !item.published.nil?
        @date = parse_time(item.published.content)
      else
        @date = parse_time(item.updated.content)
      end
      if !item.content.nil?
        @content = CGI.unescapeHTML(item.content.to_s)
      else
        @content = CGI.unescapeHTML(item.summary.to_s)
      end
      @guid = item.id.to_s
      @audio = nil # TODO podcast support for Atom feeds?
    end
  end

  # returns array of HavenFeedEntry objects
  # feed_url is the URL of a feed, eg: "https://example.com/rss.xml"
  def self.fetch_feed_content(feed_url)
    entries = nil
    cleanurl, auth_opts = parse_auth(feed_url)
    URI(cleanurl).open(auth_opts) do |rss|
      entries = parse_feed_content(rss)
    end
    entries
  end

  # returns array of HavenFeedEntry objects
  # feed_raw is a StringIO from URI.open (or a File for testing)
  def self.parse_feed_content(feed_raw)
      entries=[]
      feed = RSS::Parser.parse(feed_raw, validate: false)
      if (feed.feed_type == "rss")
        feed.items.each do |item|
          entry = HavenFeedEntry.new(feed,item)
          entries << entry
        end
      elsif (feed.feed_type == "atom")
        feed.entries.each do |item|
          entry = HavenFeedEntry.new(feed,item)
          entries << entry
        end
      end
    entries
  end

  def self.parse_auth(full_url)
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

  private

  # Different time formats were causing problems, this method standardizes them
  def parse_time(time)
    if time.is_a? Time
      return Time.parse time.httpdate
    elsif time.is_a String
      return Time.parse(Time.parse(time).httpdate)
    else
      raise "Argument Error, #{time} is not a valid time"
    end
  end

end

