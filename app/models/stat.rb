class Stat
  def total_games(user)
    finished_games(user).size
  end

  def total_wins(user)
    finished_players(user, winner: true).size
  end

  def total_losses(user)
    finished_players(user, winner: [ false, nil ]).size
  end

  def total_average(user)
    average(total_wins(user), total_games(user))
  end

  def total_games_by_game(user, type: "GoFishGame")
    finished_games(user, type:).size
  end

  def total_wins_by_game(user, type: "GoFishGame")
    finished_players(user, type:, winner: true).size
  end

  def total_losses_by_game(user, type: "GoFishGame")
    finished_players(user, type:, winner: [ false, nil ]).size
  end

  def total_average_by_game(user, type: "GoFishGame")
    average(total_wins_by_game(user, type:), total_games_by_game(user, type:))
  end

  private

  def finished_games(user, type: nil)
    games = user.games.where.not(finished_at: nil)
    type ? games.where(type:) : games
  end

  def finished_players(user, winner:, type: nil)
    players = Player.joins(:game).where(user_id: user.id, winner:).merge(Game.where.not(finished_at: nil))
    type ? players.where(games: { type: }) : players
  end

  def average(wins, total)
    return 0.0 if total.zero?

    (wins.to_f / total) * 100
  end
end
