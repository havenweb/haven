class IndieAuthScopes
  ScopeList = 
    {
      ## IndieAuth
      "profile" => "see your display name",
      "email" => "see your email address",
      ## Microsub
#      "read" => "fetch your Haven Reader feed",
#      "follow" => "subscribe to other sites in your Haven Reader",
#      "mute" => "silence a site in your Haven Reader",
#      "block" => "silence a site in your Haven Reader",
      #"channels",
      ## Micropub
#      "create" => "create a new post on your Haven",
#      "update" => "modify existing posts on your Haven",
#      "delete" => "delete posts on your Haven",
#      "media" => "upload images and other media to include them in Haven posts"
    }
  def self.valid_scopes
    ScopeList.keys
  end

  def self.scope_description(scope)
    if ScopeList.keys.include? scope
      return ScopeList[scope]
    else
      raise "#{scope} is not a valid Haven scope"
    end
  end
end
