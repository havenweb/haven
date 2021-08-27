class FeedsController < ApplicationController

  def index
    @feeds = Feed.all
    @new_feed = Feed.new # for the creation form
  end

  def create
    feed_url = params[:feed][:url]
    feed = Feed.new
    feed.url = feed_url
    feed.save
    UpdateFeedJob.perform_now(feed)
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
    UpdateFeedJob.perform_later
    @entries = FeedEntry.all.sort_by{|e| e.published}.reverse
  end
end
