class IndieAuthRequestObj
  attr_reader :response_type, :client_id, :redirect_uri, :state, :code_challenge, :code_challenge_method, :scope

  def initialize(params)
    if params[:response_type] and params[:response_type]=="code"
      @response_type = "code"
    else 
      raise "request must have a response_type parameter of 'code'"
    end
    if params[:client_id] # TODO: and valid client_id
      @client_id = params[:client_id]
    else
      raise "request must have a client_id"
    end
    if params[:redirect_uri]
      @redirect_uri = params[:redirect_uri]
    else
      raise "request must have a redirect_uri"
    end
    if params[:state]
      @state = params[:state]
    else
      raise "request must have a state"
    end
    if params[:code_challenge]
      @code_challenge = params[:code_challenge]
    else
      raise "Request must have a code_challenge.  Haven requires IndieAuth clients to use PKCE and provide a code_challenge. This client (#{@client_id}) may not be compatible."
    end      
    if params[:code_challenge_method] and params[:code_challenge_method]=="S256"
      @code_challenge_method = params[:code_challenge_method]
    else 
      raise "request must have a code_challenge_method of S256 indicating SHA256"
    end
    @scope = []
    if params[:scope] # optional
      [" ","+","%20"].each do |delim|
        if params[:scope].include? delim
          params[:scope].split(delim).each do |s| 
            @scope << s if IndieAuthScopes.valid_scopes.include? s
          end
          break
        end
      end
    end
  end  
  
end
