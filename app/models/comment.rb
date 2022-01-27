class Comment < ApplicationRecord
  belongs_to :post, inverse_of: :comments
  belongs_to :author, class_name: :User, inverse_of: :comments
end
