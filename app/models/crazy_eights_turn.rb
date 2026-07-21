class CrazyEightsTurn < Turn
  attr_accessor :rank, :suit, :wild_suit, :request

  validates :rank, presence: true, unless: :request?
  validates :suit, presence: true, unless: :request?
  validates :wild_suit, presence: true, if: :wild?, unless: :request?
  validate :valid_move

  def save
    if self.valid?
      game.play(rank: rank, suit: suit, wild_suit: wild_suit, request: !!request)
      return true
    end
    false
  end

  private

  def valid_move
    return if game.nil? || request?

    unless game.valid_move?(rank, suit)
      errors.add(:base, "Invalid player or rank!")
    end
  end

  def wild?
    rank == CrazyEights::Card::WILD_RANK
  end

  def request?
    !!request == true
  end
end
