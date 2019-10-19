class Post < ApplicationRecord
  belongs_to :author, class_name: :User
  def to_param
    return nil unless persisted?
    slug = PostsController.make_slug(content)
    [id, slug].join('-') # 1-english-for-everyone
  end
end
