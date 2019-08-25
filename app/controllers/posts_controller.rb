class PostsController < ApplicationController
  GFM_EXT = [:table, :strikethrough, :autolink, :tagfilter]

  def index
    @posts = Post.order(datetime: :desc)
    @settings = SettingsController.get_setting
    @css = true
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

  def self.make_slug(content)
    content.each_line do |line|
      puts "##{line}"
      old = line.strip
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
  end

  def self.make_title(content)
    make_slug(content).gsub("-"," ").titleize
  end


  private


  def handle_form_submit(params, view)
    @post = post_from_form(params)
    if params[:commit] == "Upload Selected Image"
      @image = Image.new
      @image.blob.attach params[:post][:pic]
      @image.save
      @post.content += "\n\n![](#{path_for(@image.blob)})"
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
