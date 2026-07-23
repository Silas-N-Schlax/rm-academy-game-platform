class RummyGame < Game
  serialize :game_state, coder: Rummy::Game

  def engine_class = Rummy::Game
end
