xml.instruct! :xml, :version => "1.0"
xml.opml :version => "2.0" do
  xml.body do
    @feeds.each do |feed|
      xml.outline(xmlUrl: feed.url) do
      end
    end
  end
end
