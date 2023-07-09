require "test_helper"

class IndieAuthTest < ActionDispatch::IntegrationTest
   test "Log in user" do
     get "/admin/users"
     assert_response :redirect # access fails before login

     # George Washington is an admin
     post user_session_path, params: {user: { 
       email:    users(:washington).email,
       password: "georgepass"
     }}

     get "/admin/users"
     assert_response :success
     assert_select "h2", "Manage Users"
   end

   test "IndieAuth profile request" do
     # log in and construct an auth request
     context = create_washington_auth_request("profile email")
     assert_response :redirect

     redirected_url = URI.parse(response.headers['Location'])
     query_parameters = CGI.parse(redirected_url.query)

     # validate the auth request and that the right data is returned
     db_auth_request = User.find(1).indie_auth_requests.last # user 1 is Washington
     assert_equal db_auth_request.state, query_parameters["state"].first
     assert_equal db_auth_request.code, query_parameters["code"].first
  
     # use the auth token to fetch a profile
     post indie_auth_profile_path, params: {
       "grant_type" => "authorization_code",
       "code" => db_auth_request.code,
       "client_id" => context["client_id"],
       "redirect_uri" => context["redirect_uri"],
       "code_verifier" => context["code_verifier"]
     }
     
     # validate response
     assert_response :success
     response_json = JSON.parse(response.body)
     ["me", "profile"].each do |k|
       assert response_json.keys.include?(k)
     end
     assert_equal User.find(1).name, response_json["profile"]["name"]
     assert_equal User.find(1).email, response_json["profile"]["email"]

     # try using the same code again, it should not work
     post indie_auth_profile_path, params: {
       "grant_type" => "authorization_code",
       "code" => db_auth_request.code,
       "client_id" => context["client_id"],
       "redirect_uri" => context["redirect_uri"],
       "code_verifier" => context["code_verifier"]
     }
     assert_response :unauthorized
   end

   test "IndieAuth token request fails with no scope" do
     # log in and construct an auth request
     context = create_washington_auth_request("") #note: empty scope
     assert_response :redirect

     redirected_url = URI.parse(response.headers['Location'])
     query_parameters = CGI.parse(redirected_url.query)
  
     # use the auth request to fetch a token
     post indie_token_endpoint_path, params: {
       "grant_type" => "authorization_code",
       "code" => query_parameters["code"].first,
       "client_id" => context["client_id"],
       "redirect_uri" => context["redirect_uri"],
       "code_verifier" => context["code_verifier"]
     }
     
     # token requests should fail for empty scope
     assert_response :bad_request
   end

   test "IndieAuth token request" do
     # log in and construct an auth request
     context = create_washington_auth_request("profile email")
     assert_response :redirect

     redirected_url = URI.parse(response.headers['Location'])
     query_parameters = CGI.parse(redirected_url.query)

     # validate the auth request and that the right data is returned
     db_auth_request = User.find(1).indie_auth_requests.last # user 1 is Washington
     assert_equal db_auth_request.state, query_parameters["state"].first
     assert_equal db_auth_request.code, query_parameters["code"].first
  
     # use the auth token to fetch a profile
     post indie_token_endpoint_path, params: {
       "grant_type" => "authorization_code",
       "code" => db_auth_request.code,
       "client_id" => context["client_id"],
       "redirect_uri" => context["redirect_uri"],
       "code_verifier" => context["code_verifier"]
     }
     
     # validate response
     assert_response :success
     response_json = JSON.parse(response.body)
     ["me", "profile", "access_token", "scope"].each do |k|
       assert response_json.keys.include?(k)
     end
     assert_equal User.find(1).name, response_json["profile"]["name"]
     assert_equal User.find(1).email, response_json["profile"]["email"]
     assert_equal User.find(1).indie_auth_tokens.first.access_token, response_json["access_token"]
     assert_equal User.find(1).indie_auth_tokens.first.scope, response_json["scope"]

     # try using the same code again, it should not work
     post indie_token_endpoint_path, params: {
       "grant_type" => "authorization_code",
       "code" => db_auth_request.code,
       "client_id" => context["client_id"],
       "redirect_uri" => context["redirect_uri"],
       "code_verifier" => context["code_verifier"]
     }
     assert_response :unauthorized
   end

   test "Validates code_verifier" do
     # log in and construct an auth request
     context = create_washington_auth_request("profile email")
     assert_response :redirect

     redirected_url = URI.parse(response.headers['Location'])
     query_parameters = CGI.parse(redirected_url.query)

     # validate the auth request and that the right data is returned
     db_auth_request = User.find(1).indie_auth_requests.last # user 1 is Washington
     assert_equal db_auth_request.state, query_parameters["state"].first
     assert_equal db_auth_request.code, query_parameters["code"].first
  
     # use the auth token to fetch a profile
     post indie_auth_profile_path, params: {
       "grant_type" => "authorization_code",
       "code" => db_auth_request.code,
       "client_id" => context["client_id"],
       "redirect_uri" => context["redirect_uri"],
       "code_verifier" => context["code_verifier"] + "1" # This should break it.
     }
     # validate response
     assert_response :unauthorized
   end

   test "Validates indie auth client redirect" do
     post user_session_path, params: {user: { 
       email:    users(:washington).email,
       password: "georgepass"
     }}
     
     auth_params = {
       response_type: "code",
       client_id: "http://localhost:12345",
       redirect_uri: "https://badsite.com/redirect", #invalid redirect
       state: SecureRandom.urlsafe_base64(10),
       code_challenge: SecureRandom.urlsafe_base64(10), #bogus, but we won't be validating it in this test
       code_challenge_method: "S256",
       scope: "profile email"
     }
     get indie_authorization_endpoint_path, params: auth_params

     assert_response :bad_request
  end

   private

   # context: scope, state, code_verifier, client_id, redirect_uri
   def create_washington_auth_request(scope)
     post user_session_path, params: {user: { 
       email:    users(:washington).email,
       password: "georgepass"
     }}
     
     context = {}
     context["scope"] = scope
     context["state"] = SecureRandom.urlsafe_base64(10)
     context["code_verifier"] = SecureRandom.urlsafe_base64(10)
     context["client_id"] = "http://localhost:12345"
     context["redirect_uri"] = "http://localhost:12345/redirect"

     approval_params = {}
     scope.split(" ").each {|s| approval_params[s] = 1}
     approval_params["code_challenge"] = 
       Base64.urlsafe_encode64(
         Digest::SHA256.digest(
           context["code_verifier"])).chomp("=")
     approval_params["commit"] = "Approve"
     ["state", "client_id", "redirect_uri"].each do |p|
       approval_params[p] = context[p]
     end


     post indie_auth_approval_path, params: approval_params
     return context
   end
end
