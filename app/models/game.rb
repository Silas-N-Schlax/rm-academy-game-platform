class Game < ApplicationRecord
  has_many :players, dependent: :destroy
  has_many :users, through: :players


  after_create_commit { broadcast_refresh_later_to "games" }
  after_update_commit { broadcast_refresh_later_to "games" }
  after_update_commit { broadcast_refresh_later_to self }

  validates :name, presence: true, length: { in: 4..25 }, uniqueness: { case_sensitive: true }
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

  def start!
    return self.game_state unless self.game_state.nil?
    return nil unless can_start?

    self.started_at = Time.current
    self.game_state = engine_class.create(self.players)
    save!
    self.game_state
  end

  def engine_class = raise NotImplementedError, "#{self.class} must implement #engine_class"
  def turn_class = raise NotImplementedError, "#{self.class} must implement #turn_class"
  def presenter_class = raise NotImplementedError, "#{self.class} must implement #presenter_class"
  def play(**) = raise NotImplementedError, "#{self.class} must implement #play"
  def valid_move?(**) = raise NotImplementedError, "#{self.class} must implement #valid_move?"
  def min_players = raise NotImplementedError, "#{self.class} must implement #min_players"
  def max_players = raise NotImplementedError, "#{self.class} must implement #max_players"

  def valid_types
    self.class.eager_load_subclasses!
    Game.descendants.map(&:name).sort
  end

  def join(user_id)
    can_join?(user_id) && players.create(user_id:)
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
      .where("(SELECT COUNT(*) FROM players WHERE players.game_id = games.id) < games.game_size")
  end

  def finished_games_by_user(user_id)
    Game.includes(:players).where.not(finished_at: nil).where(players: { user_id: })
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

  def self.eager_load_subclasses!
    return if @subclasses_loaded
    Rails.application.eager_load! unless Rails.application.config.eager_load
    @subclasses_loaded = true
  end

  private

  def format_status_message
    return "started" if self.started_at

    "#{all_players.size}/#{self.game_size} players"
  end

  def valid_game_size
    return if self.class == Game
    return if game_size.nil?

    min = self.min_players
    max = self.max_players

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
    players.update_all(winner: false)
    Player.find_by(user_id: winner_id, game_id: self.id).update!(winner: true)
  end
end
