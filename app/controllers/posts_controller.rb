class PostsController < ApplicationController
  GFM_EXT = [:table, :strikethrough, :autolink, :tagfilter]
  IMG_REGEX = /!\[.*\]\(.*\)/
  before_action :authenticate_user!, except: :rss
  before_action :verify_publisher, except: [:index, :show, :rss]

  def index
    @posts = Post.order(datetime: :desc).page(params[:page])
    @settings = SettingsController.get_setting
    @css = true
  end

  def rss
    if !check_basic_auth
      head :unauthorized
    else
      @posts = Post.order(datetime: :desc).page(1)
      @settings = SettingsController.get_setting
      render layout: false
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
    verify_can_modify_post(@post)
    @post
  end

  def create
    handle_form_submit(params, 'new')
  end

  def update
    handle_form_submit(params, 'edit')
  end

  def destroy
    @post = Post.find(params[:id])
    verify_can_modify_post(@post)
    @post.destroy
    redirect_to posts_path
  end

  ## expects import of a markdown file from a wordpress export and blog2md
  ## Example:
  ## ---
  ## title: 'post title'
  ## date: Mon, 16 Sep 2019 03:51:34 +0000
  ## ---
  ## ![](https://path.to/image.jpg)
  ##
  ## Post conent
  def import
    local_file_dir = params[:filedir]
    local_img_dir = params[:imgdir]
    Dir["#{local_file_dir}*"].each do |local_filename|
      import_md_file(local_filename, local_img_dir)
    end
    redirect_to posts_path
  end

  def new_import
    render :import
  end

  def self.sanitize(txt)
    txt.gsub(/[^0-9A-Za-z]/, '-').squeeze("-")
  end

  def self.strip_image(txt)
    img_pure = IMG_REGEX.match(txt).to_a.first
    alt_text = /\[.*\]/.match(img_pure).to_a.first.gsub(/[\[\]]/,"")
    filepath = /\(.*\)/.match(img_pure).to_a.first.gsub(/[\(\)]/,"")
    filename = filepath.split("/").last.split(".").first
    return alt_text unless alt_text.strip.empty? || alt_text.include?("/rails/active_storage/representations")
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

  # convert relative URLs to absolute URLs when referencing media (for RSS)
  # prefix should be scheme://domain, eg: "https://example.com"
  def self.convert_urls(content, prefix)
    return content.gsub("=\"/rails/active_storage/","=\"#{prefix}/rails/active_storage/")
  end

  def process_new_video(image) ## Image model used for all media
    blob_path = image_path(image)
    "\n\n<video controls><source src=\"#{blob_path}\" type=\"video/mp4\"></video>"
  end

  def process_new_audio(image) ## Image model used for all media
    blob_path = image_path(image)
    "\n\n<audio controls><source src=\"#{blob_path}\" type=\"audio/mpeg\"></audio>"
  end


  ## takes a saved Image object, returns the markdown content to refer to the image
  def process_new_image(image)
    blob_path = path_for(image.blob)
    image_meta = ActiveStorage::Analyzer::ImageAnalyzer.new(image.blob).metadata
    if image_meta[:width] > 1600 #resize at lower quality with link
      return "\n\n<a href=\"#{image_path(image)}\">\n  <img src=\"#{image_resized_path(image)}\"></img>\n</a>"
    else #simple full image
      return "\n\n<img src=\"#{image_path(image)}\"></img>"
    end
  end


  private

  def image_path(image)
    "/images/raw/#{image.id}/#{image.blob.filename.to_s}"
  end

  def image_resized_path(image)
    "/images/resized/#{image.id}/#{image.blob.filename.to_s}"
  end

  def verify_can_modify_post(post)
    unless current_user.admin==1 or post.author == current_user
      flash[:alert] = "You are not authorized to edit this post"
      redirect_to post
    end
  end

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
      file_ext = path_for(@image.blob).split(".").last
      if (file_ext == "mp3")
        @post.content += process_new_audio(@image)
      elsif (file_ext == "mp4")
        @post.content += process_new_video(@image)
      else
        @post.content += process_new_image(@image)
      end
      render view
    else
      @post.save
      redirect_to @post
    end
  end

  ## Generates a Post object from form submission content, or initializes a new one
  def post_from_form(params)
    post = Post.find_by(id: params[:id]) || Post.new
    unless post.id.nil?
      verify_can_modify_post(post)
    end
    date = params[:post][:date]
    time = params[:post][:time]
    post.datetime = DateTime.parse("#{date} #{time}")
    post.content = params[:post][:content]
    post.author = current_user
    post
  end

  #assumes url_for() returns "http://some.domain.name/path/to/obj"
  #removes domain to provide only "/path/to/obj"
  def path_for(obj)
    url = url_for(obj)
    "/#{url.split("/",4)[3]}"
  end

  ### Methods for Import
 
  ## TODO, support audio and video in import 
  def parse_img_for_import(line, img_src)
    img_file = "#{line.split("/").last.split("-").first}.jpg"
    i = Image.new
    i.blob.attach(io: File.open(img_src + img_file), filename: img_file)
    i.save
    return process_new_image(i)
  end  

  def import_md_file(filename, img_src) 
    date = ""
    out = ""
    File.open(filename) do |file|
      first = true
      heading = true
      file.each_line do |line|
        if first
          first = false
          next
        end
        if heading
          if line=="---\n"
            heading = false
            next
          end
          if line.start_with? "title: "
            title = line.chomp.split(": ",2).last[1..-2].gsub("''","'")
            out += "# #{title}\n"
          elsif line.start_with? "date: "
            d = DateTime.parse(line.split(": ",2).last)
            date = d.in_time_zone("Pacific Time (US & Canada)").strftime("%Y-%m-%d %H:%M:%S") ##TODO: import with different timezones
          end
        else #not heading
          if line.start_with? "![](http"
            out += parse_img_for_import(line, img_src)
          else
            out += line
          end
        end
      end
    end
    p = Post.new
    p.content = out
    p.datetime = date
    p.author = current_user
    p.save
    p
  end

end
