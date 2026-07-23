class RummyTurn < Turn
  attr_accessor :action, :source, :meld_index
  attr_writer :card_ids

  ACTIONS = %w[draw meld layoff discard].freeze
  SOURCES = %w[stock discard].freeze
  MIN_CARD_IDS = { "meld" => 3, "layoff" => 1, "discard" => 1 }.freeze
  MAX_CARD_IDS = { "discard" => 1 }.freeze

  validates :action, presence: true, inclusion: { in: ACTIONS }
  validates :source, presence: true, inclusion: { in: SOURCES }, if: :draw?
  validates :meld_index, presence: true, if: :layoff?
  validate :valid_card_id_count
  validate :valid_move

  def card_ids
    @card_ids || []
  end

  def meld_index=(value)
    @meld_index = value.blank? ? nil : value.to_i
  end

  def save
    if valid?
      game.play(action:, source:, card_ids:, meld_index:)
      return true
    end
    false
  end

  private

  def draw?
    action == "draw"
  end

  def layoff?
    action == "layoff"
  end

  def valid_card_id_count
    minimum = MIN_CARD_IDS[action]
    return if minimum.nil?
    errors.add(:base, card_count_message) unless card_id_count_valid?(minimum)
  end

  def card_id_count_valid?(minimum)
    maximum = MAX_CARD_IDS[action]
    card_ids.size >= minimum && (maximum.nil? || card_ids.size <= maximum)
  end

  def card_count_message
    return "Select exactly one card to discard." if action == "discard"
    return "Select at least 3 cards to lay down a meld." if action == "meld"
    "Select at least 1 card to lay off."
  end

  def valid_move
    return if game.nil? || action.blank?
    return if MIN_CARD_IDS.key?(action) && errors[:base].present?
    errors.add(:base, invalid_move_message) unless valid_move?
  end

  def valid_move?
    game.valid_move?(action:, source:, card_ids:, meld_index:)
  end

  def invalid_move_message
    return "One of the selected cards isn't in your hand." if unresolved_cards?
    return draw_error_message if action == "draw"
    return "You must draw before you can play." unless draw_step_satisfied?
    action_error_message
  end

  def unresolved_cards?
    card_ids.present? && game.implementation.cards_from_ids(card_ids).any?(&:nil?)
  end

  def draw_step_satisfied?
    game.implementation.current_result.draw_source.present? || !game.implementation.must_draw?
  end

  def draw_error_message
    return "You've already drawn this turn." if game.implementation.current_result.draw_source.present?
    return "There's nothing left to draw — go ahead and meld, lay off, or discard." unless game.implementation.must_draw?
    "You can't draw from the stock right now — draw from the discard pile instead."
  end

  def action_error_message
    return meld_error_message if action == "meld"
    return layoff_error_message if action == "layoff"
    discard_error_message
  end

  def meld_error_message
    "That's not a valid meld — melds are 3 or 4 of a kind, or 3+ in a row of the same suit."
  end

  def layoff_error_message
    return "You can't lay off until you've melded a set of your own." unless game.implementation.current_player.has_melded
    return "That meld no longer exists — pick another." if game.implementation.melds[meld_index].nil?
    "Those cards can't be laid off onto that meld."
  end

  def discard_error_message
    "You can't discard the card you just drew from the discard pile."
  end
end
