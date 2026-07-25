class CrazyEightsGame < Game
  MIN_PLAYERS = 2
  MAX_PLAYERS = 7

  serialize :game_state, coder: CrazyEights::Game

  def engine_class = CrazyEights::Game

  def play(rank: nil, suit: nil, wild_suit: nil, request: false)
    implementation = self.game_state
    implementation.play_card(rank:, suit:, wild_suit:) unless request
    implementation.request_cards if request == true
    self.game_state = implementation
    winner = implementation.winner?
    end_game(implementation.winning_player.id) if winner
    save!
  end

  def turn_class
    CrazyEightsTurn
  end

  def presenter_class = CrazyEightsPresenter

  def valid_move?(rank:, suit:)
    implementation.valid_card?(rank, suit)
  end
end
