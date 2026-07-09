class GoFishTurn
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Attributes::Normalization

  def self.model_name = ActiveModel::Name.new(self, nil, "turn")

  attr_accessor :player, :rank, :game_id, :user_id

  def game
    @game ||= Game.find_by(id: game_id)
  end

  def user
    @user ||= User.find(user_id)
  end

  def implementation
    @implementation ||= game.game_state
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
      errors.add("Invalid player or rank!")
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
    self.user_id = user_id.to_i
    self.game_id = game_id.to_i
    self.player = player.to_i
  end
end
