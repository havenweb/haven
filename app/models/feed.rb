class Feed < ApplicationRecord
  has_many :feed_entries, dependent: :destroy
  belongs_to :user, inverse_of: :feeds
  enum status: %i[feed_invalid fetch_failed fetch_succeeded]
end
