class Turn
  include ActiveModel::Model

  attr_accessor :player, :rank, :game_id, :user_id

  validate :convert_from_strings
  validates :game_id, presence: true, inclusion: { in: ->(game) { game.valid_game_ids }, message: "That game id is invalid" }
  validates :user_id, presence: true, inclusion: { in: ->(game) { game.valid_user_ids }, message: "That user id is invalid" }
  validates :player, presence: true, inclusion: { in: ->(game) { game.valid_player_ids }, message: "That player is invalid" }
  validates :rank, presence: true, inclusion: { in: ->(game) { game. valid_player_ranks }, message: "That Rank is invalid" }
  validate :is_players_turn

  def convert_from_strings
    self.player = player.to_i
    self.user_id = user_id.to_i
    self.game_id = game_id.to_i
  end

  def valid_player_ids
    return [] if Game.find_by(id: game_id).nil?

    Game.find_by(id: game_id).users.where.not(id: user_id).pluck(:id)
  end

  def valid_player_ranks
    game = Game.find_by(id: game_id)
    return [] if game.nil? || !valid_user_ids.include?(user_id)

    game_state = Game.find_by(id: game_id).game_state
    game_state.find_player(user_id).ranks
  end

  def valid_user_ids
    return [] if Game.find_by(id: game_id).nil?

    Game.find_by(id: game_id).players.where(user_id: user_id).pluck(:user_id)
  end

  def valid_game_ids
    return [] unless valid_user_ids.include?(user_id)
    Game.all.joins(:players).where(players: { user_id: }).pluck(:id)
  end

  def is_players_turn
    game = Game.find_by(id: game_id)
    return if game.nil? || game.game_state.nil?
    return true if game.game_state.current_player.id == user_id

    errors.add(:base, "It is not your turn!")
  end
end
