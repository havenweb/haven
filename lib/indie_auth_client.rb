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

  def valid_redirect? (redirect)
    return true if redirect.start_with? @client_id
    return true if @redirects.include? redirect
    #puts "redirect validation error.  Indie auth client #{@client_id} requesting redirect to #{redirect} which does not have #{@client_id} as a prefix, and is not in list of valid redirects fetched: #{@redirects.join(",")}"
    return false
  end

  def initialize(client_id)
    @client_id = client_id
    @name = "An unknown application"
    @logo = "/warning.svg"
    @url = @client_id
    @redirects = []
    if should_fetch?
      begin
        URI(client_id).open do |f|
          doc = Nokogiri::HTML(f.read)

          url = ""
          doc.xpath("//div[@class='h-app']//a[contains(@class, 'u-url')]/@href").each {|u| url = u.value}
          @url = client_id.chomp("/") + url if url.start_with? "/"

          name = ""
          doc.xpath("//div[@class='h-app']//a[contains(@class, 'p-name')]/text()").each {|n| name = n.text}
          @name = name unless name.empty?

          logo = ""
          doc.xpath("//div[@class='h-app']//img[contains(@class, 'u-logo')]/@src").each {|l| logo = l.value}
          @logo = client_id.chomp("/") + logo if logo.start_with? "/"

          raw_redirect = []
          doc.xpath("//link[@rel='redirect_uri']").each {|l| raw_redirects << l["href"]}
          raw_redirects.each do |rr|
            if rr.start_with? "/"
              @redirects << client_id.chomp("/") + rr
            else
              @redirects << rr
            end
          end
        end
      rescue
        # do we need to complain loudly if unable to fetch client_id?
      end
    else
      @name = "A test application at #{@client_id}"
    end
  end

  private

  def should_fetch?
    clean_host = parse_hostname(@client_id)
    begin
      client_id_uri = URI.parse(@client_id) #for validation only
      ip = Resolv.getaddress(clean_host)
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

  def parse_hostname(client_id)
    no_scheme = client_id
    if no_scheme.include? "://"
      scheme, no_scheme = client_id.split("://",2)
    end
    no_auth = no_scheme
    if (no_auth.include?(":") and no_auth.include?("@")) #user:pass@host
      auth, no_auth = no_scheme.split("@",2)
    end
    no_port = no_auth
    if no_port.include? ":"
      no_port, port = no_auth.split(":",2)
    end
    return no_port
  end
end
