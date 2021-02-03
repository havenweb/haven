class User < ApplicationRecord
  validates_presence_of :basic_auth_username
  validates :basic_auth_username, uniqueness: true
  validates_presence_of :basic_auth_password

  has_many :posts, foreign_key: :author_id
  has_many :comments, foreign_key: :author_id
  has_many :login_links, dependent: :destroy

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
