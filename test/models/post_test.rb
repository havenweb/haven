require 'test_helper'

class PostTest < ActiveSupport::TestCase
  test "should not save post without content" do
    p = Post.new
    assert_not p.save
  end
end
