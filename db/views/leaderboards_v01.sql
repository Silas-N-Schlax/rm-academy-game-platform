SELECT
  users.id, users.name, users.created_at,
  COUNT(games.id) AS total_games,
  COUNT(games.id) FILTER (WHERE players.winner) AS total_wins,
  COUNT(games.id) FILTER (WHERE players.winner) * 100.0
    / NULLIF(COUNT(games.id), 0) AS win_percentage,
  COALESCE(SUM(EXTRACT(EPOCH FROM (games.finished_at - games.started_at))), 0) AS seconds_played
FROM users
LEFT JOIN players ON players.user_id = users.id
LEFT JOIN games ON games.id = players.game_id
  AND games.finished_at IS NOT NULL
GROUP BY users.id
