class Post < ApplicationRecord
  belongs_to :author, class_name: :User, inverse_of: :posts
  has_many :comments, foreign_key: :post_id, dependent: :destroy
  has_many :likes, foreign_key: :post_id, dependent: :destroy
  def to_param
    return nil unless persisted?
    slug = PostsController.make_slug(content)
    [id, slug].join('-') # 1-english-for-everyone
  end

  def like_text
    reactions = Hash.new{|h,k| h[k] = []}
    likes.each do |like|
      reactions[like.reaction] << like.user.name
    end
    text = ""
    reactions.each do |reaction, names|
      text << "\n" unless text == ""
      text << "#{reaction} from"
      names.each do |name|
        text << " #{name},"
      end
    end
    return text[0...-1] # remove trailing comma
  end

  def likes_from(user)
    user_likes = []
    likes.each do |like|
      user_likes << like if like.user == user
    end
    return user_likes
  end
end
