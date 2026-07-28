class Leaderboard
  FINISHED_GAMES_JOIN = <<~SQL.squish
    LEFT JOIN players ON players.user_id = users.id
    LEFT JOIN games ON games.id = players.game_id
      AND games.finished_at IS NOT NULL
  SQL

  ROW_COLUMNS = <<~SQL.squish
    users.id, users.name, users.created_at,
    COUNT(games.id) AS total_games,
    COUNT(games.id) FILTER (WHERE players.winner) AS total_wins,
    COUNT(games.id) FILTER (WHERE players.winner) * 100.0
      / NULLIF(COUNT(games.id), 0) AS win_percentage,
    COALESCE(SUM(EXTRACT(EPOCH FROM (games.finished_at - games.started_at))), 0) AS seconds_played
  SQL

  ROW_ORDER = <<~SQL.squish
    total_wins DESC, total_games DESC, win_percentage DESC NULLS LAST,
    seconds_played DESC, users.created_at ASC
  SQL

  def rows
    User.joins(FINISHED_GAMES_JOIN)
        .select(ROW_COLUMNS)
        .group("users.id")
        .order(Arel.sql(ROW_ORDER))
  end
end
