class FeedsController < ApplicationController

  def index
    @feeds = Feed.all
    @new_feed = Feed.new # for the creation form
  end

  def create
    feed_url = params[:feed][:url].strip
    feed_url_host = URI(feed_url).host
    request_host = URI(request.base_url).host
    matching_feed = Feed.find_by(url: feed_url)
    if (feed_url_host == request_host)
      flash[:alert] = "You cannot subscribe to yourself"
    elsif matching_feed.nil?
      feed = Feed.new
      feed.url = feed_url
      feed.save
      UpdateFeedJob.perform_now(feed)
      flash[:notice] = "You've added #{feed_url} to your Feeds"
    else # feed already exists
      flash[:notice] = "You are already subscribed to #{feed_url}"
    end
    redirect_to :feeds
  end

  def destroy
    @feed = Feed.find(params[:id])
    @feed.destroy!
    redirect_to :feeds
  end

  # fetch content from feeds for reading
  def read
    UpdateFeedJob.perform_later
    @entries = FeedEntry.order(published: :desc).page params[:page]
  end

end
