class Stat
  FINISHED_GAMES_JOIN = <<~SQL.squish
    LEFT JOIN players ON players.user_id = users.id
    LEFT JOIN games ON games.id = players.game_id
      AND games.finished_at IS NOT NULL
  SQL

  LEADERBOARD_COLUMNS = <<~SQL.squish
    users.id, users.name, users.created_at,
    COUNT(games.id) AS total_games,
    COUNT(games.id) FILTER (WHERE players.winner) AS total_wins,
    COUNT(games.id) FILTER (WHERE players.winner) * 100.0
      / NULLIF(COUNT(games.id), 0) AS win_percentage,
    COALESCE(SUM(EXTRACT(EPOCH FROM (games.finished_at - games.started_at))), 0) AS seconds_played
  SQL

  LEADERBOARD_ORDER = <<~SQL.squish
    total_wins DESC, total_games DESC, win_percentage DESC NULLS LAST,
    seconds_played DESC, users.created_at ASC
  SQL

  def leaderboard
    User.joins(FINISHED_GAMES_JOIN)
        .select(LEADERBOARD_COLUMNS)
        .group("users.id")
        .order(Arel.sql(LEADERBOARD_ORDER))
  end

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
