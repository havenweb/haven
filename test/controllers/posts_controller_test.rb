require 'test_helper'

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = users(:washington)
    @publisher_user = users(:jackson)
    @target_post = Post.create!(
      author: @admin_user, 
      content: "This is the original content of the post.",
      datetime: DateTime.now.strftime("%Y-%m-%d %H:%M")
    )
  end

  # @target_post is authored by an admin user
  # @publisher_user is trying to modify the post
  # This should not be allowed
  test "prevents publisher from updating someone else's post" do
    sign_in @publisher_user

    original_content = @target_post.content
    new_params = { post: { content: "This is different-user modified content", date: DateTime.now.strftime("%Y-%m-%d"), time: DateTime.now.strftime("%H:%M") } }

    patch post_path(@target_post), params: new_params

    # 1. Assert the database did NOT change
    @target_post.reload
    assert_equal original_content, @target_post.content, "Error: The admin-owned post was modified by a publisher-user!"
    
    # 2. Assert they get bounced out correctly
    assert_redirected_to @target_post
    assert_equal "You are not authorized to edit this post", flash[:alert]
  end

end
