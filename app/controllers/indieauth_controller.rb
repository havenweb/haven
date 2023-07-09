require 'indie_auth_scopes'
require 'indie_auth_request_obj'
require 'indie_auth_request_approval'
require 'indie_auth_profile_request'
require 'indie_auth_token_request'
require Rails.root.join('lib', 'indie_auth_client') # fixes LoadError in tests?

class IndieauthController < ApplicationController
  before_action :authenticate_user!, except:[:profile, :token, :user, :metadata]
  before_action :verify_admin, except:[:profile, :token, :user, :metadata]
  protect_from_forgery with: :null_session, only:[:profile, :user]
  skip_before_action :verify_authenticity_token, only:[:profile, :user]

  def metadata
    render json: {
      "issuer" => generate_issuer,
      "authorization_endpoint" => indie_authorization_endpoint_url,
      "token_endpoint" => indie_token_endpoint_url,
      "code_challenge_methods_supported" => ["S256"],
#      "introspection_endpoint" => "TODO",
#      "introspection_endpoint_auth_methods_supported" => "TODO",
#      "revocation_endpoint" => "TODO",
#      "revocation_endpoint_auth_methods_supported" => ["none"],
      "scopes_supported" => IndieAuthScopes.valid_scopes,
      "response_types_supported" => ["code"],
      "grant_types_supported" => ["authorization_code"],
      "service_documentation" => "https://indieauth.spec.indieweb.org"
#      "userinfo_endpoint" => "TODO"
    }
  end

  def authorization
    @auth_request = IndieAuthRequestObj.new(params)
    @client = IndieAuthClient.new(@auth_request.client_id)
    if !@client.valid_redirect?(@auth_request.redirect_uri)
      head :bad_request
    end
  end

    ### sample params: {"profile"=>"1", "read"=>"1", "create"=>"0", "state"=>"18JVlvTs7lOplQ1fE4nJ", "code_challenge"=>"ZmI2MTFhMjUwMTNiMTQ5MDMzZjU3NjE3MjIwNGRlYjQyMmY4NjY4OTMzY2JjNWIwOTAwMDhjM2FlODhlMGU3MQ==", "client_id"=>"http://localhost:4567/", "redirect_uri"=>"http://localhost:4567/redirect", "commit"=>"Approve", "controller"=>"indieauth", "action"=>"approval"}
  def approval
    if params[:commit] == 'Approve'
      @request_approval = IndieAuthRequestApproval.new(params)
      @indie_auth_request = current_user.indie_auth_requests.create!(
        code: SecureRandom.urlsafe_base64(35), #creates ~47 characters
        state: @request_approval.state,
        code_challenge: @request_approval.code_challenge,
        client_id: @request_approval.client_id,
        scope: @request_approval.scope
      )
      redirect_url = @request_approval.redirect_uri
      redirect_url += "?" + URI.encode_www_form({
        "state" => @indie_auth_request.state,
        "code" => @indie_auth_request.code,
        "iss" => generate_issuer
      })
      redirect_to redirect_url, allow_other_host: true
    elsif params[:commit] == 'Deny'
      flash[:alert] = "You denied the request"
      redirect_to root
    end
  end

  def profile
    @profile_request = IndieAuthProfileRequest.new(params)
    @authorization_request = IndieAuthRequest.find_by(code: @profile_request.code)
    valid = is_auth_request_valid? @authorization_request, params
    if valid
      resp = {
        "me" => "#{generate_issuer}/indieauth/user/#{@authorization_request.user.id}"
      }
      profile_resp = {}
      if @authorization_request.scope.split(" ").include? "profile"
        profile_resp["name"] = @authorization_request.user.name
        profile_resp["url"] = resp["me"]
      end
      if @authorization_request.scope.split(" ").include? "email"
        profile_resp["email"] = @authorization_request.user.email
      end
      unless profile_resp.empty?
        resp["profile"] = profile_resp
      end
      @authorization_request.destroy!
      render json: resp.to_json
    else
      head :unauthorized #401
    end
  end

  def token
    @token_request = IndieAuthTokenRequest.new(params)
    @auth_request = IndieAuthRequest.find_by(code: @token_request.code)
    valid = is_auth_request_valid? @auth_request, params
    if valid and @auth_request.scope.empty?
      head :bad_request # no tokens allowed for empty scope
    elsif valid
      @indie_auth_token = @auth_request.user.indie_auth_tokens.create!({
        access_token: SecureRandom.urlsafe_base64(55), #creates ~74 characters
        scope: @auth_request.scope,
        client_id: @auth_request.client_id
      })  
      resp = {
        "me" => "#{generate_issuer}/indieauth/user/#{@auth_request.user.id}",
        "access_token" => @indie_auth_token.access_token,
        "token_type" => "Bearer",
        "scope" => @indie_auth_token.scope
      }
      profile_resp = {} ## refactor?  Same as profile response above.
      if @auth_request.scope.split(" ").include? "profile"
        profile_resp["name"] = @auth_request.user.name
        profile_resp["url"] = resp["me"]
      end
      if @auth_request.scope.split(" ").include? "email"
        profile_resp["email"] = @auth_request.user.email
      end
      unless profile_resp.empty?
        resp["profile"] = profile_resp
      end
      @auth_request.destroy!
      render json: resp.to_json
    else
      head :unauthorized #401
    end
  end

  def token_destroy
    token = current_user.indie_auth_tokens.find(params["token_id"])
    token.destroy!
    redirect_to request.referer
  end

  def user
    # intentionally left blank
  end

  private
  def generate_issuer
    iss = request.protocol
    if iss == "http://" and request.host_with_port.end_with? ":80"
      iss += request.host
    elsif iss == "https://" and request.host_with_port.end_with? ":443"
      iss += request.host
    else
      iss += request.host_with_port
    end
    iss
  end

  ## Note, destroys expired requests
  def is_auth_request_valid? authorization_request, params
    valid = false
    if authorization_request.nil?
      valid = false
    elsif authorization_request.created_at > 10.minutes.ago and authorization_request.used < 1
      if Base64.urlsafe_encode64(Digest::SHA256.digest(params["code_verifier"])).chomp("=") == authorization_request.code_challenge
        valid = true
        authorization_request.update!(used: 1)
      else
        logger.info("IndieAuth code_challenge #{authorization_request.code_challenge} didn't match code_verifier #{params['code_verifier']}")
        valid = false
      end
    else
      logger.info("IndieAuthRequest has expired")
      valid = false
      authorization_request.destroy!
    end
  end
end
