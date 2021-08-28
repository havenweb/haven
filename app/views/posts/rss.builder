xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title !!@settings ? @settings.title : "New Blog"
    xml.description !!@settings ? @settings.subtitle : "Blog Description"
    xml.link root_url

    @posts.each do |post|
      rss_content = CommonMarker.render_html(post.content, [:UNSAFE, :HARDBREAKS], PostsController::GFM_EXT)
      if @settings.comments 
        if post.comments.size > 0
          rss_content += "\n<p><strong>Comments:</strong></p>"
        end
        post.comments.each do |comment|
          rss_content += "\n<small>#{comment.author.name}</small>"
          rss_content += "\n<br/>#{comment.body}<br/><br/>"
        end
        rss_content += "\n<a href=\"#{post_url(post)}\">Add a comment</a>"
      end
      xml.item do
        xml.title PostsController.make_title(post.content)
        xml.description PostsController.convert_urls(rss_content.html_safe, request.base_url)
        xml.pubDate post.datetime.rfc822
        xml.link post_url(post)
        xml.guid post_url(post)
      end
    end
  end
end
