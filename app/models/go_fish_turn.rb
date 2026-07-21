class GoFishTurn
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Attributes::Normalization

  def self.model_name = ActiveModel::Name.new(self, nil, "turn")

  attr_accessor :player, :rank, :game, :user

  def implementation
    @implementation ||= game.game_state
  end

  before_validation :normalize_inputs

  validates :game, presence: true
  validates :user, presence: true, inclusion: { in: ->(turn) { turn.game ? turn.game.users : [] } }
  validates :player, presence: true
  validates :rank, presence: true
  validate :valid_move

  def save
    if self.valid?
      game.play(player, rank, user.id)
      return true
    end
    false
  end

  def valid_move
    return if game.nil?

    unless game.valid_move?(player, rank)
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
