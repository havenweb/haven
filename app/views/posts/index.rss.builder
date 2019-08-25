xml.instruct! :xml, version: '1.0'
xml.rss version: '2.0' do
  xml.channel do
    xml.title 'Books List'
    xml.description 'Books List'
    xml.link posts_url
 
    @posts.each do |post|
      xml.item do
        xml.name PostsController.make_title(post.content)
        xml.description CommonMarker.render_html(post.content, :UNSAFE, PostsController::GFM_EXT).html_safe
        xml.link post_url(post)
      end
    end
  end
end
