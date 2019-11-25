xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title !!@settings ? @settings.title : "New Blog"
    xml.description !!@settings ? @settings.subtitle : "Blog Description"
    xml.link root_url

    @posts.each do |post|
      xml.item do
        xml.title PostsController.make_title(post.content)
        xml.description CommonMarker.render_html(post.content, :UNSAFE, PostsController::GFM_EXT).html_safe
        xml.pubDate post.datetime.rfc822
        xml.link post_url(post)
        xml.guid post_url(post)
      end
    end
  end
end
