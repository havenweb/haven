require 'test_helper'

class StaticControllerTest < ActionDispatch::IntegrationTest
  test "should get markdown" do
    get static_markdown_url
    assert_response :success
  end

end
