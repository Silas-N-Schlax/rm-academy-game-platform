class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :games, dependent: :destroy

  attribute :confirm_password

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: { case_insensitive: true }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { in: 6..20 }, comparison: { equal_to: :confirm_password }

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
