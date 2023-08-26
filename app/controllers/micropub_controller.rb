class MicropubController < ApplicationController

  skip_before_action :verify_authenticity_token
  before_action :set_auth_token

  def query
    unless params[:q]
      raise JsonError.new("invalid_request","This action requires a query to be specified with the 'q' parameter",400)
    end
    if params[:q] == "config"
      render json: {
        "media-endpoint" => micropub_media_url,
        "post-types" => [
          {
            "type": "note",
            "name": "Post",
            "properties": [ "content", "published" ]
          },
        ]
      }, status: 200
    elsif params[:q] == "source"
      validate_scope("update")
      if params[:url]
        post = post_from_url(params[:url])
        render json: post_to_mf2(post), status: 200
      else
      #list of all posts (TODO: filtering and pagination)
        posts = @token.user.posts
        mf2_posts = posts.map {|post| post_to_mf2(post)}
        render json: {
          items: mf2_posts
        }, status: 200
      end
    else
      raise JsonError.new("invalid_request","Unrecognized 'q' parameter: #{params[:q]}",400)
    end

  end

  # micropub overloads POSTs to a single endpoint for create/update/delete
  # so this method handles all three
  def create
    validate_scope("create")
    raw_action = request.request_parameters["action"]
    if (raw_action) and (raw_action == "update")
      validate_scope("update")
      if params[:url]
        post = post_from_url(params[:url])
        begin
          if params[:replace]
            if params[:replace][:content]
              new_content = params[:replace][:content]
              new_content = new_content.first if new_content.is_a? Array
              post.update(content: new_content)
            end
            if params[:replace][:published]
              new_published = Datetime.parse(params[:replace][:published].first)
              post.update(datetime: new_published)
            end
          end
          if params[:add]
            raise JsonError.new(
              "invalid_request",
              "None of the poperties this server supports (content, published) allow multiple values",
              400)
          end
          if params[:delete]
            raise JsonError.new(
              "invalid_request",
              "All properties are required (content, published), none can be deleted",
              400)
          end
        rescue => e
          raise JsonError.new(
            "invalid_request",
            "#{e.class.name}: #{e.message}",
            400)
        end ## end begin/rescue
      else # no url param
        raise JsonError.new(
          "invalid_request",
          "Request includes an action of 'update' but is missing the URL of the post to update",
          400)
        return
      end
    elsif (raw_action) and (raw_action == "delete")
      validate_scope("delete")
      if params[:url]
        post = post_from_url(params[:url])
        begin
          post.destroy!
        rescue => e
          raise JsonError.new(
            "server_error",
            "#{e.class.name}: #{e.message}",
            500)
        end
        head 204 # no content from successful deletion
      else
        raise JsonError.new("invalid_request",
          "Request includes an action of 'delete' but is missing the URL of the post to delete",
          400)
      end
    elsif (raw_action and raw_action=="create") or (raw_action.nil?) # no action should be a create
      @post = post_from_params(params)
      @post.author = @token.user
      @post.save!
      response.set_header("Location", url_for(@post))
      head 201 #created
    elsif (raw_action) # unknown action
      raise JsonError.new("invalid_request",
        "Request includes an unrecognized action of '#{raw_action}', only 'update' and 'delete' are recognized",
        400, request_json: params)
    else
      raise JsonError.new("invalid_request",
        "Unable to parse request, you shouldn't really be able to get to this error",
        400, request_json: params)
    end
  end

  def media
    validate_scope("media")
    if params[:file].nil?
      raise JsonError.new("invalid_request",
        "Request to media endpoint requires a object named 'file'",
        400, request_json: params)
    end
    image = Image.new
    image.blob.attach params[:file]
    image.save
    location = request.base_url + "/images/raw/#{image.id}/#{image.blob.filename.to_s}"
    response.set_header("Location", location)
    head 201 #created
  end

  private

  # may return 404 directly if post not found
  def post_from_url(params_url)
    post = nil
    post_path = params_url
    if params_url.include? "://"
      post_path = params_url.split("://",2).last.split("/",2).last
    end
    if post_path.include? "posts/"
      post_id = post_path.split("posts/",2).last
      begin
        post = @token.user.posts.find(post_id)
      rescue
        post = nil
      end
    end
    if post.nil?
      raise JsonError.new("not found","No post found at url: #{params_url}",404)
    end
    return post
  end

  # supported params: name, content, published
  def post_from_params(params)
    unless params[:h] and params[:h]=="entry"
      raise JsonError.new("invalid_request","Only h-entry types supported by this server",400)
    end
    content = ""
    if params[:content]
      content = params[:content]
      if params[:name]
        content = "# #{params[:name]}\n\n#{content}"
      end
    elsif params[:name]
      content = "# #{params[:name]}"
    else
      raise JsonError.new("invalid_request","New h-entry must have content or a name (or both)",400)
    end
    datetime = DateTime.now
    if params[:published]
      datetime = DateTime.parse(params[:published])
    end
    post = Post.new
    post.datetime = datetime
    post.content = content
    return post  
  end

  def post_to_mf2(post)
    {
      type: [ "h-entry" ],
      properties: {
        content: [ post.content ],
        published: [ post.datetime.iso8601 ],
        url: [ url_for(post) ]
      }
    }
  end
end
