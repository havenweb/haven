## Adapted from https://github.com/damog/feedbag/blob/master/lib/feedbag.rb
## Original copyright notice retained below

# Copyright (c) 2008-2019 David Moreno <damog@damog.net>
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

class Feedbag

  CONTENT_TYPES = [
    'application/x.atom+xml',
    'application/atom+xml',
    'application/xml',
    'text/xml',
    'application/rss+xml',
    'application/rdf+xml',
#    'application/json',
#    'application/feed+json'
  ].freeze

  def self.feed?(url)
    new.feed?(url)
  end

  def self.find(url, args = {})
    new.find(url, args = {})
  end

  def initialize
    @feeds = []
  end

  def feed?(url)
    # use LWR::Simple.normalize some time
    url_uri = URI.parse(url)
    url = "#{url_uri.scheme or 'https'}://#{url_uri.host}#{url_uri.path}"
    url << "?#{url_uri.query}" if url_uri.query

      # hack:
      url.sub!(/^feed:\/\//, 'https://')

    res = Feedbag.find(url)
    if res.size == 1 and res.first == url
      return true
    else
      return false
    end
  end

  def find(url, args = {})
    url_uri = URI.parse(url)
    url = nil
    if url_uri.scheme.nil?
      url = "https://#{url_uri.to_s}"
    elsif url_uri.scheme == "feed"
      return self.add_feed(url_uri.to_s.sub(/^feed:\/\//, 'https://'), nil)
    else
      url = url_uri.to_s
    end
    #url = "#{url_uri.scheme or 'http'}://#{url_uri.host}#{url_uri.path}"

    # check if feed_valid is avail
    begin
      require "feed_validator"
      v = W3C::FeedValidator.new
      v.validate_url(url)
      return self.add_feed(url, nil) if v.valid?
    rescue LoadError
      # scoo
    rescue REXML::ParseException
      # usually indicates timeout
      # TODO: actually find out timeout. use Terminator?
      # $stderr.puts "Feed looked like feed but might not have passed validation or timed out"
    rescue => ex
      $stderr.puts "#{ex.class} error occurred with: `#{url}': #{ex.message}"
    end

    begin
      html = URI.open(url) do |f|
        content_type = f.content_type.downcase
        if content_type == "application/octet-stream" # open failed
          content_type = f.meta["content-type"].gsub(/;.*$/, '')
        end
        if CONTENT_TYPES.include?(content_type)
          return self.add_feed(url, nil)
        end

        doc = Nokogiri::HTML(f.read)

        if doc.at("base") and doc.at("base")["href"]
          @base_uri = doc.at("base")["href"]
        else
          @base_uri = nil
        end

        # first with links
        (doc/"atom:link").each do |l|
          next unless l["rel"] && l["href"].present?
          if l["type"] and CONTENT_TYPES.include?(l["type"].downcase.strip) and l["rel"].downcase == "self"
            self.add_feed(l["href"], url, @base_uri)
          end
        end

        doc.xpath("//link[@rel='alternate' or @rel='service.feed'][@href][@type]").each do |l|
          if CONTENT_TYPES.include?(l['type'].downcase.strip)
            self.add_feed(l["href"], url, @base_uri)
          end
        end

#        doc.xpath("//link[@rel='alternate' and @type='application/json'][@href]").each do |e|
#          self.add_feed(e['href'], url, @base_uri) if self.looks_like_feed?(e['href'])
#        end

        (doc/"a").each do |a|
          next unless a["href"]
          if self.looks_like_feed?(a["href"]) and (a["href"] =~ /\// or a["href"] =~ /#{url_uri.host}/)
            self.add_feed(a["href"], url, @base_uri)
          end
        end

        (doc/"a").each do |a|
          next unless a["href"]
          if self.looks_like_feed?(a["href"])
            self.add_feed(a["href"], url, @base_uri)
          end
        end

        # Added support for feeds like http://tabtimes.com/tbfeed/mashable/full.xml
        if url.match(/.xml$/) and doc.root and doc.root["xml:base"] and doc.root["xml:base"].strip == url.strip
          self.add_feed(url, nil)
        end
      end
    rescue Timeout::Error => err
      $stderr.puts "Timeout error occurred with `#{url}: #{err}'"
    rescue OpenURI::HTTPError => the_error
      $stderr.puts "Error occurred with `#{url}': #{the_error}"
    rescue SocketError => err
      $stderr.puts "Socket error occurred with: `#{url}': #{err}"
    rescue => ex
      $stderr.puts "#{ex.class} error occurred with: `#{url}': #{ex.message}"
    ensure
      return @feeds
    end

  end

  def looks_like_feed?(url)
    if url =~ /(\.(rdf|xml|rss)(\?([\w'\-%]?(=[\w'\-%.]*)?(&|#)?)+)?(:[\w'\-%]+)?$|feed=(rss|atom)|(atom|feed)\/?$)/i
      true
    else
      false
    end
  end

  def add_feed(feed_url, orig_url, base_uri = nil)
    # puts "#{feed_url} - #{orig_url}"
    url = feed_url.sub(/^feed:/, '').strip

    if base_uri
      #	url = base_uri + feed_url
      url = URI.parse(base_uri).merge(feed_url).to_s
    end

    begin
      uri = URI.parse(url)
    rescue
      puts "Error with `#{url}'"
      exit 1
    end
    unless uri.absolute?
      orig = URI.parse(orig_url)
      url = orig.merge(url).to_s
    end

    # verify url is really valid
    @feeds.push(url) unless @feeds.include?(url)# if self._is_http_valid(URI.parse(url), orig_url)
  end

end
