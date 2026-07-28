module LeaderboardHelper
  FILTER_STATS = { total_wins: "Won", total_games: "Games" }.freeze

  def leaderboard_filters(wins_bounds:, games_bounds:)
    bounds_by_column = { total_wins: wins_bounds, total_games: games_bounds }
    FILTER_STATS.filter_map { |column, label| leaderboard_filter_chip(column, label, bounds_by_column.fetch(column)) }
  end

  def leaderboard_filter_chip(column, label, bounds)
    gteq = params.dig(:q, "#{column}_gteq").presence&.to_i
    lteq = params.dig(:q, "#{column}_lteq").presence&.to_i
    return if (gteq.nil? || gteq <= bounds.first) && (lteq.nil? || lteq >= bounds.last)
    { column: column, label: "#{label}: #{gteq || bounds.first}–#{lteq || bounds.last}", remove_url: leaderboard_url_without(column) }
  end

  def leaderboard_url_without(column)
    stripped_q = (params[:q] || {}).to_unsafe_h.except("#{column}_gteq", "#{column}_lteq")
    url_for(request.query_parameters.merge("q" => stripped_q, "page" => nil))
  end
end
