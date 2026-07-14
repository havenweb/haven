require 'resolv'
require 'nokogiri'

## fetch information about a client from a client_id url
class IndieAuthClient
  attr_reader :client_id, :name, :logo, :url

  def to_html
    output = ""
    output += "<p class=\"indie-client-logo\"><img src=\"#{@logo}\" width=\"96\"/></p><br/>"
    output += "<p class=\"indie-client-name\">#{@name}</p><br/>"
    output += "<p class=\"indie-client-id\">#{@client_id}</p><br/>"
    return output
  end

  def valid_redirect?(redirect)
    return true if @redirects.include?(redirect)
    begin
      client_uri = URI.parse(@client_id)
      redirect_uri = URI.parse(redirect)
      return true if redirect_uri.host && 
                     client_uri.scheme == redirect_uri.scheme &&
                     client_uri.host == redirect_uri.host &&
                     client_uri.port == redirect_uri.port
    rescue URI::InvalidURIError
      return false
    end
    # puts "Redirect validation error: Client #{@client_id} requested invalid redirect #{redirect}."
    false
  end

  def initialize(client_id)
    @client_id = client_id
    @name = "An unknown application"
    @logo = "/warning.svg"
    @url = @client_id
    @redirects = []
    if should_fetch? @client_id
      begin
        URI(client_id).open do |f|
          if f.content_type == 'application/json' || client_id.end_with?('.json')
            parse_json_client(f.read)
          else
            parse_html_client(f.read)
          end
          @logo = "/warning.svg" unless should_fetch? @logo
        end
      rescue
        # do we need to complain loudly if unable to fetch client_id?
      end
    else
      @name = "A test application at #{@client_id}"
    end
  end

  private

  def parse_json_client(raw_content)
    data = JSON.parse(raw_content)

    @name = data['client_name'] unless data['client_name'].nil? || data['client_name'].empty?
    
    # Handle optional relative paths for URL and Logo, though JSON usually uses absolute URIs
    @url = data['client_uri']
    @url = client_id.chomp("/") + @url if @url&.start_with?("/")

    @logo = data['logo_uri']
    @logo = client_id.chomp("/") + @logo if @logo&.start_with?("/")

    raw_redirects = data['redirect_uris'] || []
    raw_redirects.each do |rr|
      if rr.start_with?("/")
        @redirects << client_id.chomp("/") + rr
      else
        @redirects << rr
      end
    end
  end

  def parse_html_client(raw_content)

          doc = Nokogiri::HTML(raw_content)

          url = ""
          doc.xpath("//div[@class='h-app']//a[contains(@class, 'u-url')]/@href").each {|u| url = u.value}
          @url = client_id.chomp("/") + url if url.start_with? "/"

          name = ""
          doc.xpath("//div[@class='h-app']//a[contains(@class, 'p-name')]/text()").each {|n| name = n.text}
          @name = name unless name.empty?

          logo = ""
          doc.xpath("//div[@class='h-app']//img[contains(@class, 'u-logo')]/@src").each {|l| logo = l.value}
          @logo = client_id.chomp("/") + logo if logo.start_with? "/"

          raw_redirects = []
          doc.xpath("//link[@rel='redirect_uri']").each {|l| raw_redirects << l["href"]}
          raw_redirects.each do |rr|
            if rr.start_with? "/"
              @redirects << client_id.chomp("/") + rr
            else
              @redirects << rr
            end
          end
  end

  ## Protect against server-side request forgery (SSRF) by validating the IP address
  def should_fetch?(suspect_url)
    return false unless URI(suspect_url).scheme=="https"
    clean_host = URI.parse(suspect_url).host
    puts "DEBUG: clean host: #{clean_host}"
    begin
      client_id_uri = URI.parse(suspect_url) #for validation only
      puts "DEBUG: client_id_uri: #{client_id_uri}"
      ip = Resolv.getaddress(clean_host)
      puts "DEBUG: ip resolved: #{ip}"
      return safe_ip? ip
    rescue
      return false
    end
  end

  # See: https://en.wikipedia.org/wiki/Reserved_IP_addresses
  def safe_ip?(ip)
    return false if ip.start_with? "0."
    return false if ip.start_with? "10."
    return false if ip.start_with? "127."
    return false if ip.start_with? "169.254."
    return false if ip.start_with? "192.0.0."
    return false if ip.start_with? "192.0.2."
    return false if ip.start_with? "192.168."
    return false if ip.start_with? "::1"
    return false if ip.start_with? "fc"
    return false if ip.start_with? "fd"
    return false if ip.start_with? "fe80::"
    return true
  end
end
