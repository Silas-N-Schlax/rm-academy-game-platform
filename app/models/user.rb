class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :players
  has_many :games, through: :players

  attribute :confirm_password

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: { case_insensitive: true }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { in: 6..20 }, comparison: { equal_to: :confirm_password }, on: :create

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # validate :test

  # def test
  #   binding.irb
  # end

  def has_games?
    return false if self.games.empty?
    return true unless self.games.where(finished_at: nil).empty?

    false
  end
end
