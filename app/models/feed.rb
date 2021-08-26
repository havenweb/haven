class Feed < ApplicationRecord
  has_many :feed_entries, dependent: :destroy
  enum status: %i[feed_invalid fetch_failed fetch_succeeded]
end
