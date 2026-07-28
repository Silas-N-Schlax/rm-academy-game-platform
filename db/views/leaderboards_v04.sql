SELECT
  users.id, users.name, users.created_at,
  COUNT(games.id) AS total_games,
  COUNT(games.id) FILTER (WHERE players.winner) AS total_wins,
  CASE WHEN COUNT(games.id) >= 5 THEN
    COUNT(games.id) FILTER (WHERE players.winner) * 100.0
      / NULLIF(COUNT(games.id), 0)
  END AS win_percentage,
  COALESCE(SUM(EXTRACT(EPOCH FROM (games.finished_at - games.started_at))), 0) AS seconds_played,
  ROW_NUMBER() OVER (
    ORDER BY
      COUNT(games.id) FILTER (WHERE players.winner) DESC,
      COUNT(games.id) DESC,
      COALESCE(SUM(EXTRACT(EPOCH FROM (games.finished_at - games.started_at))), 0) DESC,
      COUNT(games.id) FILTER (WHERE players.winner) * 100.0
        / NULLIF(COUNT(games.id), 0) DESC NULLS LAST,
      users.created_at ASC
  ) AS rank
FROM users
LEFT JOIN players ON players.user_id = users.id
LEFT JOIN games ON games.id = players.game_id
  AND games.finished_at IS NOT NULL
GROUP BY users.id
