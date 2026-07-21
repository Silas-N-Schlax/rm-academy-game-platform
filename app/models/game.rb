class Game < ApplicationRecord
  has_many :players, dependent: :destroy
  has_many :users, through: :players


  after_create_commit { broadcast_refresh_later_to "games" }
  after_update_commit { broadcast_refresh_later_to "games" }
  after_update_commit { broadcast_refresh_later_to self }

  validates :name, presence: true, length: { minimum: 4 }
  validates :type, presence: true, inclusion: { in: ->(game) { game.valid_types } }
  validates :game_size, presence: true
  validate :valid_game_size

  normalizes :type, with: ->(t) { t.split(" ").join }

  def implementation
    @implementation ||= game_state
  end

  def save_new_game(user_id)
    self.players.new(user_id: user_id)
    self.save
  end

  def start! = raise NotImplementedError, "#{self.class} must implement #required_method"
  def play = raise NotImplementedError, "#{self.class} must implement #required_method"
  def turn_class = raise NotImplementedError, "#{self.class} must implement #required_method"

  def valid_types
    game_details_hash.keys
  end

  def game_size_by_type(type)
    game_details_hash[type]
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

  def open_games(user_id)
    Game.joins(:players)
      .where(finished_at: nil, started_at: nil, archived_at: nil)
      .group("games.id")
      .having("COUNT(players.id) < games.game_size")
  end

  def winner
    self.players.find_by(winner: true)
  end

  def players_turn?(user_id)
    implementation.current_player.id == user_id
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
    return "started" if self.started_at

    "#{all_players.size}/#{self.game_size} players"
  end

  def valid_game_size
    valid_game_size = game_size_by_type(type)
    return if valid_game_size.nil? || game_size.nil?

    min = valid_game_size[:min]
    max = valid_game_size[:max]

    if game_size < min || game_size > max
      errors.add(:game_size, "Game size must be between #{min} and #{max} players for #{type}.")
    end
  end

  def all_players
    Player.where(game_id: self.id)
  end

  def can_start?
    players.size == game_size
  end

  def end_game(winner_id)
    self.finished_at = Time.current
    player = Player.find_by(user_id: winner_id, game_id: self.id)
    player.winner = true
    player.save!
  end


  def game_details_hash
    {
      "GoFishGame" => {
        min: 2,
        max: 6
      },
      "CrazyEightsGame" => {
        min: 2,
        max: 7
      }
    }
  end
end
