class Game < ApplicationRecord
  has_many :players, dependent: :destroy

  validates :name, presence: true, length: { minimum: 4 }
  validates :game_type, presence: true, inclusion: { in: ->(game) { game.valid_game_types } }
  # ^ Create enum for game_type validation
  validates :game_size, presence: true
  validate :valid_game_size

  def valid_game_types
    game_details_hash.keys
  end

  def game_size_by_game_type(game_type)
    game_details_hash[game_type]
  end

  def can_join?(user_id)
    return false if self.started_at
    return true if open_spots? && !joined?(user_id)

    false
  end

  def joined?(user_id)
    players = Player.where(user_id:)
    return true if players.find { |player| player.game_id == self.id }

    false
  end

  def open_spots?
    return true if self.all_players.size < self.game_size

    false
  end

  def status(message: false)
    response = nil
    response = "waiting" if self.started_at.nil?
    response = "started" if self.started_at && self.finished_at.nil?
    response = "finished" if self.finished_at

    response = format_status_message if message
    response
  end

  private

  def format_status_message
    return "started" unless open_spots?

    "#{all_players.size}/#{self.game_size} players"
  end

  def valid_game_size
    valid_game_size = game_size_by_game_type(game_type)
    return if valid_game_size.nil? || game_size.nil?

    min = valid_game_size[:min]
    max = valid_game_size[:max]

    if game_size < min || game_size > max
      errors.add(:game_size, "Game size must be between #{min} and #{max} players for #{game_type}.")
    end
  end

  def all_players
    Player.where(game_id: self.id)
  end


  def game_details_hash
    {
      "Go Fish" => {
        min: 2,
        max: 6
      }
    }
  end
end
