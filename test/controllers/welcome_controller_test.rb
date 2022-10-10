require 'test_helper'

class WelcomeControllerTest < ActionDispatch::IntegrationTest
  test "should redirec to login" do
    get '/'
    assert_redirected_to posts_url
  end

end
