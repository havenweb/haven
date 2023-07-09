require "test_helper"

class IndieAuthTest < ActionDispatch::IntegrationTest
   test "IndieAuth metadata has valid issuer" do
     get indie_auth_metadata_path
     assert_response :success
     response_json = JSON.parse(response.body)
     # per IndieAuth spec, issuer MUST be a prefix of the metadata path
     assert indie_auth_metadata_url.start_with? response_json["issuer"]     
   end
end
