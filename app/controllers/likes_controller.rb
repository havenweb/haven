class LikesController < ApplicationController
  def create
    post = Post.find(params[:post_id])
    @like = post.likes.create(user_id: current_user.id)
    @like.save!
    redirect_to post, notice: "You have liked this post"
#    redirect_back(fallback_location: post)
  end

  def destroy
    @like = Like.find(params[:like_id])
    post = @like.post
    if (@like.user.id == current_user.id || current_user.admin == 1)
      @like.destroy
    end
    redirect_to post, notice: "Your like has been removed from this post"
#    redirect_back(fallback_location: post)
  end
end
