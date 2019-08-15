class Image < ApplicationRecord
  has_one_attached :blob
end
