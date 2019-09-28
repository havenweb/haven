class PostsController < ApplicationController
  GFM_EXT = [:table, :strikethrough, :autolink, :tagfilter]
  IMG_REGEX = /!\[.*\]\(.*\)/
  before_action :authenticate_user!
  before_action :verify_admin, except: [:index, :show]

  def index
    @posts = Post.order(datetime: :desc).page(params[:page])
    @settings = SettingsController.get_setting
    @css = true
    respond_to do |format|
      format.html
      format.rss { render layout: false }
    end
  end

  def show
    @post = Post.find(params[:id])
    @settings = SettingsController.get_setting
    @css = true
  end

  def new
    @post ||= Post.new
    @post.datetime = DateTime.now if @post.datetime.nil?
    @post.content = "" if @post.content.nil?
  end

  def edit
    @post = Post.find(params[:id])
  end

  def create
    handle_form_submit(params, 'new')
  end

  def update
    handle_form_submit(params, 'edit')
  end

  def destroy
    @post = Post.find(params[:id])
    @post.destroy
    redirect_to posts_path
  end

  def self.sanitize(txt)
    txt.gsub(/[^0-9A-Za-z]/, '-').squeeze("-")
  end

  def self.strip_image(txt)
    img_pure = IMG_REGEX.match(txt).to_a.first
    alt_text = /\[.*\]/.match(img_pure).to_a.first.gsub(/[\[\]]/,"")
    filepath = /\(.*\)/.match(img_pure).to_a.first.gsub(/[\(\)]/,"")
    filename = filepath.split("/").last.split(".").first
    return alt_text unless alt_text.strip.empty?
    return filename
  end

  def self.make_slug(content)
    fallback = "post"
    content.each_line do |line|
      if IMG_REGEX.match(line) && (fallback == "post")
        fallback = strip_image(line)
      end
      old = ActionController::Base.helpers.strip_tags(line.gsub(/['"]/,"").strip)
        .gsub("!","") ## these remove markdown images
        .gsub(/\(.*\)/,"")
        .gsub(/\[.*\]/,"")
        .squeeze("#") ## treat all headers the same
      next if old.empty?
      if old[0]=="#"
         old = old[1..-1].strip
      end
      next unless old.length > 3
      return sanitize(old)[0..50].downcase
    end
    return sanitize(fallback)[0..50].downcase
  end

  def self.make_title(content)
    make_slug(content).gsub("-"," ").titleize
  end


  private

  def require_signed_in
    if !user_signed_in?
      redirect_to new_user_session_path
    end
  end

  def handle_form_submit(params, view)
    @post = post_from_form(params)
    if params[:commit] == "Upload Selected Image"
      @image = Image.new
      @image.blob.attach params[:post][:pic]
      @image.save
      blob_path = path_for(@image.blob)
      image_meta = ActiveStorage::Analyzer::ImageAnalyzer.new(@image.blob).metadata
      if image_meta[:width] > 1600 #resize at lower quality with link
        variant = @image.blob.variant(combine_options:{thumbnail: "1600", quality: '65%', interlace: 'plane'}).processed
        variant_path = path_for(variant)
        @post.content += "\n\n[![](#{variant_path})](#{blob_path})"
      else #simple full image
        @post.content += "\n\n![](#{blob_path})"
      end
      render view
    else
      @post.save
      redirect_to @post
    end
  end

  def post_from_form(params)
    post = Post.find_by(id: params[:id]) || Post.new
    date = params[:post][:date]
    time = params[:post][:time]
    post.datetime = DateTime.parse("#{date} #{time}")
    post.content = params[:post][:content]
    post
  end

  #assumes url_for() returns "http://some.domain.name/path/to/obj"
  #removes domain to provide only "/path/to/obj"
  def path_for(obj)
    url = url_for(obj)
    "/#{url.split("/",4)[3]}"
  end
end
