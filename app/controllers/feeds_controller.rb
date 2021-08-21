class FeedsController < ApplicationController

  # Constants for feed entry keys
  ENTRY_TITLE = "title"
  FEED_TITLE = "feed"
  ENTRY_LINK = "link"
  ENTRY_DATE = "date"
  ENTRY_CONTENT = "content"  

  def index
    @feeds = Feed.all
    @new_feed = Feed.new # for the creation form
  end

  def create
    feed_url = params[:feed][:url]
    feed_name = fetch_feed_title(feed_url)
    feed = Feed.new
    feed.url = feed_url
    feed.name = feed_name
    feed.save
    flash[:notice] = "You've added #{feed_url} to your Feeds"
    redirect_to :feeds
  end

  def destroy
    @feed = Feed.find(params[:id])
    @feed.destroy!
    redirect_to :feeds
  end

  # fetch content from feeds for reading
  def read
    @entries = []
    Feed.all.each do |feed|
      @entries.concat fetch_feed_content(feed.url)
    end
    @entries = @entries.sort_by{ |e| e[ENTRY_DATE] }.reverse
  end

  private

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
          entries << entry
        end
      end
    end
    entries
  end
end
