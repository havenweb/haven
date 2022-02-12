class Like < ApplicationRecord
  belongs_to :post, inverse_of: :likes
  belongs_to :user, inverse_of: :likes
end
