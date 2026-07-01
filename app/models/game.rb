class Game < ApplicationRecord
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

  private

  def valid_game_size
    valid_game_size = game_size_by_game_type(game_type)
    return if valid_game_size.nil? || game_size.nil?

    min = valid_game_size[:min]
    max = valid_game_size[:max]

    if game_size < min || game_size > max
      errors.add(:game_size, "Game size must be between #{min} and #{max} players for #{game_type}.")
    end
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
