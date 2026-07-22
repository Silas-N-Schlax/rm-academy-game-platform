class GoFishGame < Game
  serialize :game_state, coder: GoFish::Game

  def engine_class = GoFish::Game

  def play(player:, rank:)
    implementation = self.game_state
    implementation.run_turn(player.to_i, rank)
    self.game_state = implementation
    end_game(implementation.winning_player.id) if implementation.winner?
    save!
  end

  def remaining_turn_seconds(total)
    elapsed = Time.current - updated_at
    (total - elapsed).clamp(0, total)
  end

  def valid_move?(player:, rank:)
    implementation.valid_player?(player) && implementation.valid_rank?(rank)
  end

  def turn_class
    GoFishTurn
  end

  def players_list(user_id)
    implementation = self.game_state
    implementation.list_of_players(user_id)
  end

  def ranks_list(user_id)
    implementation = self.game_state
    implementation.list_of_ranks(user_id)
  end
end
