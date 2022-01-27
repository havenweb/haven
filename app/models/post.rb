class Post < ApplicationRecord
  belongs_to :author, class_name: :User, inverse_of: :posts
  has_many :comments, foreign_key: :post_id, dependent: :destroy
  def to_param
    return nil unless persisted?
    slug = PostsController.make_slug(content)
    [id, slug].join('-') # 1-english-for-everyone
  end
end
