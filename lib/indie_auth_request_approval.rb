class IndieAuthRequestApproval
  attr_reader :scope, :state, :code_challenge, :client_id, :redirect_uri

  def initialize(params)
    @scope = self.class.parse_scopes(params)
    if params[:state]
      @state = params[:state]
    else
      raise "request must pass a state"
    end
    if params[:code_challenge]
      @code_challenge = params[:code_challenge]
    else
      raise "request must pass a code_challenge"
    end
    if params[:client_id]
      @client_id = params[:client_id]
    else
      raise "request must pass a client_id"
    end
    if params[:redirect_uri]
      @redirect_uri = params[:redirect_uri]
    else
      raise "request must pass a redirect_uri"
    end
  end

  def self.parse_scopes(params)
    scopes_array = []
    IndieAuthScopes.valid_scopes.each do |s|
      if params.keys.include? s and params[s]=="1"
        scopes_array << s
      end
    end
    return scopes_array.join(" ")
  end 
end
