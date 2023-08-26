require "test_helper"

class IndieAuthTest < ActionDispatch::IntegrationTest

   test "can subscribe to feeds with microsub" do
     token = create_washington_auth_token("profile email read follow")  

     # fetch (empty) feed list
     get '/microsub', params: {
       access_token: token,
       action: "follow",
       channel: "default"
     }

     assert_response :success
     response_json = JSON.parse(response.body)   
     assert response_json.keys.include? "items"
     assert_equal response_json["items"], []

     # subscribe to a feed
     feed_url = "https://havenweb.org/feed.xml"
     post '/microsub', params: {
       access_token: token,
       action: "follow",
       channel: "default",
       url: feed_url
     }

     assert_response :created
     response_json = JSON.parse(response.body)   
     assert_equal response_json["type"], "feed"
     assert_equal response_json["url"], feed_url

     # fetch (populated) feed list
     get '/microsub', params: {
       access_token: token,
       action: "follow",
       channel: "default"
     }

     assert_response :success
     response_json = JSON.parse(response.body)   
     assert response_json.keys.include? "items"
     assert_equal response_json["items"].size, 1

     # fetch timeline
     get '/microsub', params: {
       access_token: token,
       action: "timeline",
       channel: "default"
     }

     assert_response :success
     response_json = JSON.parse(response.body)
     assert response_json["items"].size > 0
     assert_equal response_json["items"].first["type"], "entry"
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

   def create_washington_auth_token(scope)
     context = create_washington_auth_request(scope)
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
     assert_response :success
     response_json = JSON.parse(response.body)
     assert response_json.keys.include?("access_token")
     return response_json["access_token"]
  end
end
