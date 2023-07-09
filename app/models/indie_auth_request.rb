class IndieAuthRequest < ApplicationRecord
  belongs_to :user
  validates :code_challenge, presence: true
  validates :client_id, presence: true
end
