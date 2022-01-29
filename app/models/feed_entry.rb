class FeedEntry < ApplicationRecord
  belongs_to :feed, inverse_of: :feed_entries
end
