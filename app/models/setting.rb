class Setting < ApplicationRecord
  has_many_attached :fonts
  has_one_attached :favicon_original
  has_one_attached :favicon_ico
  has_one_attached :favicon_apple_touch
  has_one_attached :favicon_32x32
  has_one_attached :favicon_16x16
  has_one_attached :favicon_512x512
end
