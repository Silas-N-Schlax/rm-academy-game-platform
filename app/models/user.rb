class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :players
  has_many :games, through: :players

  attribute :password_confirmation

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: { case_insensitive: true }, format: { with: URI::MailTo::EMAIL_REGEXP }, on: :create
  validates :password, presence: true, length: { in: 6..20 }, on: :create
  validates :password_confirmation, presence: true, unless: -> { password.nil? }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def has_games?
    return false if self.games.empty?
    return true unless self.games.where(finished_at: nil).empty?

    false
  end

  def country_flag
    return unless self.country
    self.country.upcase.chars.map { |char| char.ord + 127397 }.pack("U*")
  end
end
