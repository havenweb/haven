require "test_helper"

class IndieAuthTest < ActionDispatch::IntegrationTest

   test "can post with micropub" do
     token = create_washington_auth_token("profile email create update")  

     # create a new post
     post_content = Random.rand.to_s
     post micropub_path, params: {
       h: "entry",
       content: post_content,
       access_token: token
     }

     # validate response
     assert_response :created
     post_url = response.headers['Location']
     assert_not_nil post_url
     post_id = post_url.split("posts/",2).last
     db_post = Post.find(post_id)

     assert_equal db_post.content, post_content

     #fetch post with micropub
     get micropub_path, params: {
       access_token: token,
       q: "source",
       url: post_url
     }
     
     assert_response :success
     response_json = JSON.parse(response.body)   
     assert_equal response_json["type"], ["h-entry"]
     assert_equal response_json["properties"]["content"], [post_content]
     assert_equal response_json["properties"]["url"], [post_url]
   end

   test "can't post with micropub without create scope" do
     token = create_washington_auth_token("profile email update")  

     # create a new post
     post_content = Random.rand.to_s
     post micropub_path, params: {
       h: "entry",
       content: post_content,
       access_token: token
     }

     # fails without create scope
     assert_response :forbidden
   end

   test "can't post without an auth token" do
     post micropub_path, params: {
       h: "entry",
       content: "I'm a post!",
     }
     assert_response :unauthorized
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
