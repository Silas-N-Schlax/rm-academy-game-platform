class Turn
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Attributes::Normalization

  def self.model_name = ActiveModel::Name.new(self, nil, "turn")

  attr_accessor :game, :user

  def implementation
    @implementation ||= game.game_state
  end

  validates :game, presence: true
  validates :user, presence: true, inclusion: { in: ->(turn) { turn.game ? turn.game.users : [] } }
  validate :players_turn

  private

  def players_turn
    return if game.nil? || user.nil?
    errors.add(:base, "Its not your turn!") unless game.players_turn?(user.id)
  end
end
