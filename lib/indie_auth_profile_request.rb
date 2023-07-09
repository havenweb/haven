class IndieAuthProfileRequest
  attr_reader :grant_type, :code, :client_id, :redirect_uri, :code_verifier

  def initialize(params)
    if params[:grant_type] and params[:grant_type] == "authorization_code"
      @grant_type = params[:grant_type]
    else 
      raise "Profile request must have a grant_type of authorization_code"
    end

    if params[:code]
      @code = params[:code]
    else
      raise "Profile request must have a code"
    end

    if params[:client_id]
      @client_id = params[:client_id]
    else
      raise "Profile request must have a client_id"
    end

    if params[:redirect_uri]
      @redirect_uri = params[:redirect_uri]
    else
      raise "Profile request must have a redirect_uri"
    end

    if params[:code_verifier]
      @code_verifier = params[:code_verifier]
    else
      raise "Profile request must have a code_verifier, found: #{params.to_s}"
    end
  end  
end
