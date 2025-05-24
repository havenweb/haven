class Setting < ApplicationRecord
  has_many_attached :fonts
  has_one_attached :favicon_original # Only this one for favicons
end
