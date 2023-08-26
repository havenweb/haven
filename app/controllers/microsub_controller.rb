class MicrosubController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_auth_token

  def get
    # rails overwrites params[:action] with the controller action name
    # we can use this syntax to fetch the original `action`
    raw_action = request.query_parameters["action"]
    if raw_action
      if raw_action=="timeline"
        get_timeline(params)
      elsif raw_action=="follow"
        get_subscriptions(params)
      elsif raw_action=="channels"
        list_channels
      else
        raise JsonError.new("invalid_request", "This request has an unknown action of #{raw_action}", 400)
      end
    else
      raise JsonError.new("invalid_request","Microsub requests must have an action parameter", 400)
    end
  end

  def create
    raw_action = request.request_parameters["action"]
    if raw_action
      if raw_action == "follow"
        subscribe_to_feed(params)
      elsif raw_action == "unfollow"
        unsubscribe_from_feed(params)
      else
        raise JsonError.new("invalid_request", "This request has an unknown action of #{params[:action]}", 400)
      end
    else
      raise JsonError.new("invalid_request","Microsub requests must have an action parameter", 400)
    end
  end

  private

  def get_timeline(params)
    validate_scope("read")
    @paging = nil
    if params[:before] and params[:after]
      @entries = @token.user.feed_entries
        .where('sort_date < ?', params[:before])
        .where('sort_date > ?', params[:after])
        .order(sort_date: :desc).limit(20)
    elsif params[:before]
      @entries = @token.user.feed_entries
        .where('sort_date < ?', params[:before])
        .order(sort_date: :desc).limit(20)
    elsif params[:after]
      @entries = @token.user.feed_entries
        .where('sort_date > ?', params[:after])
        .order(sort_date: :desc).limit(20)
    else
      @entries = @token.user.feed_entries
        .order(sort_date: :desc).limit(20)
    end
    unless @entries.count < 20
      @paging = {
        before: @entries.last.sort_date.iso8601,
        after: @entries.first.sort_date.iso8601
      }
    end
    items = @entries.map{|e| 
        {
          type: "entry",
          published: e.published.iso8601,
          url: e.link,
          uid: e.guid,
          name: e.title,
          content: {html: e.content},
          author: {type: 'card', name: e.feed.name, url: e.feed.url},
          _id: e.id
        }
    }
    result = {}
    result[:items] = items
    result[:paging] = @paging unless @paging.nil?
    render json: result, status: 200
  end

  def get_subscriptions(params)
    validate_scope("read")
    items = []
    if params[:channel] and params[:channel] == "default"
      @token.user.feeds.each do |feed|
        items << {
          type: "feed",
          name: feed.name,
          url: feed.url
        }
      end
    end
    render json: {items: items}, status: 200
  end

  def list_channels
    validate_scope("read")
    items = []
    render json: {
      channels: [
        {uid: "notifications", name: "Notifications"},
        {uid: "default", name: "Default"}
      ]
    }
  end

  def subscribe_to_feed(params)
    validate_scope("follow")
    if params[:channel] and params[:channel] == "default"
      feed_url = params[:url]
      raise JsonError.new("invalid_request","A URL is required for this action", 400) if feed_url.nil?
      ## duplicate code as feed_controller#add_feed
      feed_url_host = URI(feed_url).host
      request_host = URI(request.base_url).host
      matching_feed = Feed.find_by(url: feed_url, user: current_user)
      if (feed_url_host == request_host)
        raise JsonError.new("invalid_request","You cannot subscribe to yourself", 400)
      elsif matching_feed.nil?
        feed = @token.user.feeds.create!(url: feed_url)
        UpdateFeedJob.perform_now(feed)
        if feed.feed_invalid?
          raise JsonError.new("invalid_request","Error adding #{feed_url} to your feeds", 400)
        else
          render json: {type: "feed", url: feed_url}, status: 201
        end
      else # feed already exists
        render json: {type: "feed", url: feed_url}, status: 200
      end
    else
      raise JsonError.new("invalid_request","This server only allows subscribing to the 'default' channel", 400)
    end
  end

  def unsubscribe_from_feed(params)
    validate_scope("follow")
    if params[:channel] and params[:channel] == "default"
      if params[:url]
        feed = @token.user.feeds.find_by(url: params[:url])
        if feed.nil?
          raise JsonError.new("not_found", "No feed found with URL #{params[:url]}", 404)
        else
          feed.destroy!
          head 204
        end
      else
        raise JsonError.new("invalid_request", "A URL is required for this action", 400)
      end
    else
      raise JsonError.new("invalid_request", "This server only allows managing subscriptions on the 'default' channel", 400)
    end
  end
end
