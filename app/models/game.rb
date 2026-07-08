class Game < ApplicationRecord
  has_many :players, dependent: :destroy
  has_many :users, through: :players
  serialize :game_state, coder: GoFish::Game

  validates :name, presence: true, length: { minimum: 4 }
  validates :game_type, presence: true, inclusion: { in: ->(game) { game.valid_game_types } }
  validates :game_size, presence: true
  validate :valid_game_size

  def start!
    return self.game_state unless self.game_state.nil?
    return nil unless can_start?

    self.started_at = Time.current
    self.updated_at = self.started_at
    self.game_state = GoFish::Game.create(self.players)
    save!
    self.game_state
  end

  def play(player, rank, user_id)
    game_state = self.game_state
    game_state.run_turn(player.to_i, rank)
    self.game_state = game_state
    self.updated_at = Time.current
    end_game(game_state.winner.id) if game_state.winner
    save!
  end


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
    return true if Player.find_by(user_id:, game_id: self.id)

    false
  end

  def open_spots?
    return true if self.all_players.size < self.game_size

    false
  end

  def open_games
    Game.where.missing(:players)
      .where(finished_at: nil, started_at: nil)
      .group("games.id")
      .having("COUNT(players.id) < games.game_size")
  end

  def winner
    self.players.find_by(winner: true)
  end

  def status(message: false)
    response = nil
    response = "waiting" if self.started_at.nil?
    response = "started" if self.started_at && self.finished_at.nil?
    response = "finished" if self.finished_at

    response = format_status_message if message
    response
  end

  def formatted_time
    return 0 unless self.finished_at
    total_seconds = self.finished_at - self.started_at
    hours = total_seconds / 3600
    minutes = (total_seconds % 3600) / 60
    seconds = total_seconds % 60
    format("%02d:%02d:%02d", hours, minutes, seconds)
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

  def can_start?
    players.size == game_size
  end

  def end_game(winner_id)
    self.finished_at = updated_at
    player = Player.find_by(user_id: winner_id, game_id: self.id)
    player.winner = true
    player.updated_at = Time.current
    player.save!
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
