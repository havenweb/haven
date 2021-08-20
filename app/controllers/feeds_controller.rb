class FeedsController < ApplicationController
  def index
    @feeds = Feed.all
    @new_feed = Feed.new # for the creation form
  end

  def create
    feed_url = params[:feed][:url]
    feed_name = "Unverified Feed"
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
end
