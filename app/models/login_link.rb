class LoginLink < ApplicationRecord
  belongs_to :user
  def self.generate(user)
    return nil if !user
    create(user: user, token: generate_token)
  end

  def self.generate_token
    Devise.friendly_token.first(20)
  end
end
