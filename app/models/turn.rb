class Turn
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Attributes::Normalization

  attr_accessor :player, :rank, :game_id, :user_id

  def game
    @game ||= Game.find_by(id: game_id)
  end

  def user
    @user ||= User.find(user_id)
  end

  before_validation :normalize_inputs

  normalizes :user_id, :player, :game_id, with: ->(value) { value.to_i }

  validates :game_id, presence: true
  validates :game, presence: true
  validates :user, presence: true, inclusion: { in: ->(turn) { turn.game ? turn.game.users : [] } }
  validates :user_id, presence: true
  validates :player, presence: true
  validates :rank, presence: true
  validate :valid_move

  def valid_turn?
    if self.valid?
      game.play(player, rank, user.id)
      return true
    end
    false
  end

  def valid_move
    return if game.nil?

    unless game.valid_move?(player, rank)
      errors.add("Invalid player or rank!")
    end
  end

  private

  def normalize_inputs
    self.user_id = user_id.to_i
    self.game_id = game_id.to_i
    self.player = player.to_i
  end
end
