class RummyGame < Game
  serialize :game_state, coder: Rummy::Game

  def engine_class = Rummy::Game

  def turn_class = RummyTurn

  def play(action:, source: nil, card_ids: [], meld_index: nil)
    implementation = self.game_state
    dispatch_play(implementation, action:, source:, card_ids:, meld_index:)
    self.game_state = implementation
    end_game(implementation.winning_player.id) if implementation.winner?
    save!
  end

  def valid_move?(action:, source: nil, card_ids: [], meld_index: nil)
    implementation.valid_move?(action:, source:, card_ids:, meld_index:)
  end

  private

  def dispatch_play(implementation, action:, source:, card_ids:, meld_index:)
    cards = implementation.cards_from_ids(card_ids)
    return implementation.draw(source:) if action == "draw"
    return implementation.lay_down_meld(cards) if action == "meld"
    return implementation.lay_off(meld_index, cards) if action == "layoff"
    implementation.discard_card(cards.first) if action == "discard"
  end
end
