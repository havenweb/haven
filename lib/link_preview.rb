
module LinkPreview
  require 'open-uri'
  require 'nokogiri'
  require 'microformats'
  require 'metainspector'
  require 'cgi'
  
  def self.fetch(url)
    begin
      uri = URI.parse(url)
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        raise ArgumentError, "Only HTTP/HTTPS URLs are allowed"
      end
      html = uri.open.read
    rescue StandardError => e
      puts "Failed to fetch URL: #{e.message}"
      return nil
    end
    
    doc = Nokogiri::HTML(html)
    
    # Check for standard mf2 root classes
    if false # mf2 parsing isn't working well TODO: investigate further
#    if doc.at_css('.h-entry, .h-card, .h-event')
      # puts "mf2 detected! Parsing with microformats-ruby..."
      parsed = Microformats.parse(html)
      entry = parsed.items.first
      raw_description = entry.properties['summary']&.first || entry.properties['content']&.first
      clean_description = if raw_description.is_a?(Hash)
                            # Handle both string and symbol keys just in case
                            raw_description['value'] || raw_description[:value] || ""
                          else
                            raw_description
                          end
      return {
        title: entry.properties['name']&.first,
        description: clean_description.truncate(250, separator: ' '),
        image: entry.properties['photo']&.first,
        type: 'mf2'
      }
      
    else
      # puts "No mf2 found. Falling back to MetaInspector..."
      page = MetaInspector.new(url, document: html)
      
      return {
        title: page.best_title,
        description: page.best_description,
        image: page.images.best,
        type: 'opengraph'
      }
    end
  end
  
  
  def self.render(url, preview)
    # Fallback to a standard link if the preview hash is nil
    return %Q(<a href="#{url}">#{url}</a>) if preview.nil?
  
    # Safely escape text to prevent XSS injection
    title = CGI.escapeHTML(preview[:title] || url)
    description = CGI.escapeHTML(preview[:description] || "")
    
    # Conditionally render the image tag only if an image exists
    image_html = if preview[:image]
                   %Q(<img src="#{preview[:image]}" alt="Preview for #{title}" class="preview-image">)
                 else
                   ""
                 end
    description_html = description.empty? ? "" : %Q(<p class="preview-description">#{description}</p>)
               
  
    <<~HTML
      <a href="#{url}" class="link-preview-card">
        #{image_html}
        <div class="preview-content">
          <strong class="preview-title">
            #{title}
          </strong>
          #{description_html}
        </div>
      </a>
    HTML
  end

end # Module
