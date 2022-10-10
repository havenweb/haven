require 'test_helper'

class StaticControllerTest < ActionDispatch::IntegrationTest
  test "should get markdown" do
    get '/markdown'
    assert_redirected_to new_user_session_url
  end

end
