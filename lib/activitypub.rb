class ActivityPub
  def self.fetch(url)
    JSON.parse(URI.open(url).read)
  rescue
    raise "Could not fetch JSON data at URL #{url}"
  end
  
  def self.has_actor_data?(url)
    data = fetch(url)
    ["id", "outbox", "url", "name"].each do |key|
      if data.keys.include? key
        next
      else
        raise "#{input} is invalid ActivityPub URL, missing Actor key #{key}"
      end
    end
    return true
  rescue => e
    # $stderr.puts "ERROR: #{e.message}"
    return false
  end
  
  def self.huristic_actor_url(input)
    if input.start_with? "@" and input.count("@")==2 # @user@domain.ext
      _,user,domain = input.split("@")
      return "https://#{domain}/users/#{user}"
    elsif input.start_with? "http"
      if input.include? "@"  #eg http://domain/@user
        return "#{input}.json"
      else  # eg http://domain/users/user
        return input
      end
    else # hope for the best?
      return "https://#{input}"
    end
  end
  
  def self.discover_actor_url(input)
    actor = huristic_actor_url(input)
    actor_dot_json = "#{actor}.json"
    if has_actor_data? actor
      return actor
    elsif has_actor_data? actor_dot_json
      return actor_dot_json
    else
      raise "Cannot find an Activity Pub Actor for #{input}"
    end
  end
  
  def self.is_actor?(input)
    actor = discover_actor_url(input)
    return true
  rescue
    return false
  end

  def self.fetch_name(input)
    actor = discover_actor_url(input)
    data = fetch(actor)
    return data["name"]
  end
  
  def self.fetch_notes(actor)
    actor_url = discover_actor_url(actor)
    actor_data = fetch(actor_url)
    outbox_url = actor_data["outbox"]
    outbox_data = fetch(outbox_url)
    first_outbox_url = outbox_data['first']
    first_outbox_data = fetch(first_outbox_url)
    notes = []
    first_outbox_data['orderedItems'].each do |item|
      if item["type"] == "Create"
        #puts "Found Create for Object:"
        #pp item["object"]
        if item["object"]["type"] == "Note"
          notes << item["object"]
        end
      else
        ## log there was a non-note item?
      end
    end
    return notes
  rescue => e
    raise "Failed to fetch notes for #{actor} because #{e.message}"
  end
 
  def self.transform_content(item)
    output=[]
    if item["inReplyTo"]
      output << "Replying To <a href=\"#{item["inReplyTo"]}\">#{item["inReplyTo"]}</a>"
    end
    output << item["content"]
    item["attachment"].each do |attachment|
      if attachment["mediaType"].start_with? "image/"
        output << "<img src=\"#{attachment["url"]}\"/>"
      elsif attachment["mediaType"].start_with? "video/"
        output << "<video controls><source src=\"#{attachment["url"]}\" type=\"#{attachment["mediaType"]}\"></video>"
      elsif attachment["mediaType"].start_with? "audio/"
        output << "<audio controls><source src=\"#{attachment["url"]}\" type=\"#{attachment["mediaType"]}\"></audio>"
      else
        puts "Attachment: <a href=\"#{attachment["url"]}\">#{attachment["url"]}</a>"  ## insert raw link.
      end
    end
    return output.join("<br/>\n")
  end
end
