class FeedsController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_admin

  def index
    @feeds = current_user.feeds
    @new_feed = Feed.new # for the creation form
  end

  def create
    feed_url = params[:feed][:url].strip
    unless (feed_url.start_with? "http")
      feed_url = "https://" + feed_url
    end
    feed_url_host = URI(feed_url).host
    request_host = URI(request.base_url).host
    matching_feed = Feed.find_by(url: feed_url, user: current_user)
    if (feed_url_host == request_host)
      flash[:alert] = "You cannot subscribe to yourself"
    elsif matching_feed.nil?
      feed = current_user.feeds.create!(url: feed_url)
      UpdateFeedJob.perform_now(feed)
      flash[:notice] = "You've added #{feed_url} to your Feeds"
    else # feed already exists
      flash[:notice] = "You are already subscribed to #{feed_url}"
    end
    redirect_to :feeds
  end

  def destroy
    @feed = Feed.find(params[:id])
    if ( (!@feed.nil?) and (current_user == @feed.user) )
      @feed.destroy!
    else
      flash[:alert] = "You cannot do that"
    end
    redirect_to :feeds
  end

  # fetch content from feeds for reading
  def read
    UpdateFeedJob.perform_later
    @entries = current_user.feed_entries.order(sort_date: :desc).page params[:page]
  end

  def read_feed
    @feed = Feed.find(params[:id])
    @entries=[]
    if ( (!@feed.nil?) and (current_user == @feed.user) )
      @entries = @feed.feed_entries.order(sort_date: :desc).page params[:page]
      UpdateFeedJob.perform_later(@feed)
      render :read
    else
      flash[:alert] = "That does not exist"
      redirect_to :root
    end
  end

end
