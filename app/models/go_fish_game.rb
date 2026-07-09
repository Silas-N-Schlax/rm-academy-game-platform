class GoFishGame < Game
  serialize :game_state, coder: GoFish::Game

  def start!
    return self.game_state unless self.game_state.nil?
    return nil unless can_start?

    self.started_at = Time.current
    self.game_state = GoFish::Game.create(self.players)
    save!
    self.game_state
  end

  def play(player, rank, user_id)
    implementation = self.game_state
    implementation.run_turn(player.to_i, rank)
    self.game_state = implementation
    winner = implementation.winner
    end_game(winner.id) if winner
    save!
  end

  def valid_move?(player, rank)
    implementation.valid_player?(player) && implementation.valid_rank?(rank)
  end

  def turn_class
    GoFishTurn
  end
end
