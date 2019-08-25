class Post < ApplicationRecord
  def to_param
    return nil unless persisted?
    slug = PostsController.make_slug(content)
    [id, slug].join('-') # 1-english-for-everyone
  end
end
