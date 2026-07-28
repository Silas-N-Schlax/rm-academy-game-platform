SELECT
  ROW_NUMBER() OVER () AS id,
  players.user_id,
  games.type,
  COUNT(games.id) AS total_games,
  COUNT(games.id) FILTER (WHERE players.winner) AS total_wins,
  COALESCE(SUM(EXTRACT(EPOCH FROM (games.finished_at - games.started_at))), 0) AS seconds_played,
  MIN(games.started_at) AS first_played_at
FROM players
JOIN games ON games.id = players.game_id
  AND games.finished_at IS NOT NULL
GROUP BY GROUPING SETS ((players.user_id, games.type), (players.user_id))
