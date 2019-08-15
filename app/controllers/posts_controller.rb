class PostsController < ApplicationController

  def show
    @post = Post.find(params[:id])
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
    @post_html = markdown.render(@post.content).html_safe
  end

  def new
    @post = Post.new
    @post.datetime = DateTime.now
    @post.content = ""
  end

  def create
    @post = Post.new
    date = params[:post][:date]
    time = params[:post][:time]
    @post.datetime = DateTime.parse("#{date} #{time}")
    @post.content = params[:post][:content]
    @post.save
    redirect_to @post
  end
end
