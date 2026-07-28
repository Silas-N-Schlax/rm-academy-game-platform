module LeaderboardHelper
  FILTER_STATS = { total_wins: "Won", total_games: "Games" }.freeze
  TEXT_FILTER_STATS = { name: "Name" }.freeze

  def leaderboard_filters(wins_bounds:, games_bounds:)
    bounds_by_column = { total_wins: wins_bounds, total_games: games_bounds }
    range_chips = FILTER_STATS.filter_map { |column, label| leaderboard_range_filter_chip(column, label, bounds_by_column.fetch(column)) }
    text_chips = TEXT_FILTER_STATS.filter_map { |column, label| leaderboard_text_filter_chip(column, label) }
    range_chips + text_chips + [ leaderboard_country_filter_chip ].compact
  end

  def leaderboard_range_filter_chip(column, label, bounds)
    gteq = params.dig(:q, "#{column}_gteq").presence&.to_i
    lteq = params.dig(:q, "#{column}_lteq").presence&.to_i
    return if (gteq.nil? || gteq <= bounds.first) && (lteq.nil? || lteq >= bounds.last)
    { column: column, label: "#{label}: #{gteq || bounds.first}–#{lteq || bounds.last}", remove_url: leaderboard_url_without("#{column}_gteq", "#{column}_lteq") }
  end

  def leaderboard_text_filter_chip(column, label)
    value = params.dig(:q, "#{column}_cont").presence
    return if value.nil?
    { column: column, label: "#{label}: #{value}", remove_url: leaderboard_url_without("#{column}_cont") }
  end

  def leaderboard_country_filter_chip
    code = params.dig(:q, "user_country_eq").presence
    return if code.nil?
    { column: :country, label: "Country: #{Country.data.find(code)&.name || code}", remove_url: leaderboard_url_without("user_country_eq") }
  end

  def leaderboard_url_without(*keys)
    stripped_q = (params[:q] || {}).to_unsafe_h.except(*keys)
    url_for(request.query_parameters.merge("q" => stripped_q, "page" => nil))
  end
end
