class CrazyEightsTurn
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Attributes::Normalization

  def self.model_name = ActiveModel::Name.new(self, nil, "turn")

  attr_accessor :game, :user, :rank, :suit, :wild_suit, :request

  def implementation
    @implementation ||= game.game_state
  end

  validates :game, presence: true
  validates :user, presence: true
  validates :user, presence: true, inclusion: { in: ->(turn) { turn.game ? turn.game.users : [] } }
  validates :rank, presence: true, unless: :request?
  validates :suit, presence: true, unless: :request?
  validates :wild_suit, presence: true, if: :wild?, unless: :request?
  validate :is_players_turn?
  validate :valid_move

  def save
    if self.valid?
      game.play(rank: rank, suit: suit, wild_suit: wild_suit, request: request)
      return true
    end
    false
  end

  private

  def is_players_turn?
    return if game.nil? || user.nil?
    unless implementation.current_player.id == user.id
      errors.add("Its not your turn!")
    end
  end

  def valid_move
    return if game.nil? || request?

    unless game.valid_move?(rank, suit)
      errors.add("Invalid player or rank!")
    end
  end

  def wild?
    rank == CrazyEights::Card::WILD_RANK
  end

  def request?
    request == true
  end
end
