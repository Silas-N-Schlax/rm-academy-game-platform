class Turn
  include ActiveModel::Model

  attr_accessor :player, :rank, :game_id, :user_id

  validates :game_id, presence: true, inclusion: { in: ->(game) { game.valid_game_ids } }
  validates :user_id, presence: true, inclusion: { in: ->(game) { game.valid_user_ids } }
  validates :player, presence: true, inclusion: { in: ->(game) { game.valid_player_ids } }
  validates :rank, presence: true, inclusion: { in: ->(game) { game. valid_player_ranks } }
  validate :is_players_turn

  def valid_player_ids
    return [] if Game.find_by(id: game_id).nil?

    Game.find_by(id: game_id).players.where.not(user_id:).pluck(:id)
  end

  def valid_player_ranks
    game = Game.find_by(id: game_id)
    return [] if game.nil? || !valid_user_ids.include?(user_id)

    game_state = Game.find_by(id: game_id).game_state
    game_state.find_player(user_id).ranks
  end

  def valid_user_ids
    return [] if Game.find_by(id: game_id).nil?

    Game.find_by(id: game_id).players.where(user_id:).pluck(:user_id)
  end

  def valid_game_ids
    return [] unless valid_user_ids.include?(user_id)
    Game.all.joins(:players).where(players: { user_id: }).pluck(:id)
  end

  def is_players_turn
    game = Game.find_by(id: game_id)
    return if game.nil?
    return true if game.game_state.current_player.id == user_id

    errors.add(:base, "It is not your turn!")
  end
end
