class IndieAuthToken < ApplicationRecord
  belongs_to :user
  validates :access_token, presence: true
  validates :client_id, presence: true
end
