class ApplicationController < ActionController::Base
  class JsonError < StandardError
    attr_accessor :error, :error_description, :status, :options
    def initialize(error, error_description, status, options={})
      @error = error
      @error_description = error_description
      @status = status
      @options = options
    end
    def to_json
      j = { error: @error, error_description: @error_description}
      options.each {|k,v| j[k]=v}
      return j
    end
  end


  before_action :configure_permitted_parameters, if: :devise_controller?
  rescue_from JsonError, with: :json_error_handler

  def json_error_handler(json_error)
    render json: json_error.to_json, status: json_error.status
  end

  def set_auth_token
    token = nil
    if params[:access_token]
      token = IndieAuthToken.find_by(access_token: params[:access_token])
    elsif request.headers["Authorization"]
      t = request.headers["Authorization"]
      if t.start_with? "Bearer "
        t2 = t.split("Bearer ",2).last
        token = IndieAuthToken.find_by(access_token: t2)
      end
    end
    if token.nil?
      raise JsonError.new("unauthorized", "This action requires an authentication token", 401)
    end
    @token = token
  end

  def validate_scope(scope)
    unless @token.scope.split(" ").include? scope
      raise JsonError.new("insufficient_scope","The provided authentication token does not include the scope: '#{scope}' which is required for this action", 403, scope: scope)
    end
  end
 
  def self.get_settings
    return Setting.first || Setting.new
  end

  def basic_auth_user
    basic_auth_header = request.authorization
    credentials = Base64.decode64(basic_auth_header.split("Basic ").last)
    basic_auth_user, basic_auth_pass = credentials.split(":")
    user = User.find_by(basic_auth_username: basic_auth_user)
    return user
  rescue
    return nil
  end

  def check_basic_auth
    basic_auth_header = request.authorization
    if basic_auth_header.nil?
      return false
    end
    credentials = Base64.decode64(basic_auth_header.split("Basic ").last)
    basic_auth_user, basic_auth_pass = credentials.split(":")
    if (basic_auth_user.nil? || basic_auth_pass.nil?)
      return false
    end
    user = User.find_by(basic_auth_username: basic_auth_user)
    if (user.nil? || user.basic_auth_password != basic_auth_pass)
      return false
    end
    return true
  end

  private
  
  def verify_admin
    if current_user.admin != 1
      redirect_to posts_path
    end
  end 
  
  def verify_publisher
    if current_user.admin < 1 # 1 is admin, 2 is publisher
      redirect_to posts_path
    end
  rescue
    redirect_to posts_path
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end
end
