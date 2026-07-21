class GoFishTurn < Turn
  attr_accessor :player, :rank

  before_validation :normalize_inputs

  validates :player, presence: true
  validates :rank, presence: true
  validate :valid_move

  def save
    if self.valid?
      game.play(player:, rank:)
      return true
    end
    false
  end

  def valid_move
    return if game.nil?

    unless game.valid_move?(player:, rank:)
      errors.add(:base, "Invalid player or rank!")
    end
  end

  def players
    implementation.list_of_players(user.id)
  end

  def ranks
    implementation.list_of_ranks(user.id)
  end

  private

  def normalize_inputs
    self.player = player.to_i
  end
end
