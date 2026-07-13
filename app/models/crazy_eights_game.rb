class CrazyEightsGame < Game
  serialize :game_state, coder: CrazyEights::Game

  def start!
    return self.game_state unless self.game_state.nil?
    return nil unless can_start?

    self.started_at = Time.current
    self.game_state = CrazyEights::Game.create(self.players)
    save!
    self.game_state
  end
  # ^ move to super class with a thing like turn class??

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

  def valid_move?(rank, suit)
    implementation.valid_card?(rank, suit)
  end
end
