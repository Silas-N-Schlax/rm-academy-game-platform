class Leaderboard < ApplicationRecord
  SORT_OPTIONS = {
    "total_games" => "Games",
    "total_wins" => "Won",
    "win_percentage" => "W/L",
    "seconds_played" => "Time Played"
  }.freeze

  SORT_COLUMNS = SORT_OPTIONS.keys.freeze

  PER_PAGE_OPTIONS = [ 10, 25, 50, 100 ].freeze
  DEFAULT_PER_PAGE = 50
  MIN_PER_PAGE = PER_PAGE_OPTIONS.min
  MAX_PER_PAGE = PER_PAGE_OPTIONS.max

  def self.clamp_per_page(value)
    return DEFAULT_PER_PAGE if value.blank?
    value.to_i.clamp(MIN_PER_PAGE, MAX_PER_PAGE)
  end

  UNIVERSAL_RANK_ORDER = [
    "total_wins DESC NULLS LAST",
    "total_games DESC NULLS LAST",
    "seconds_played DESC NULLS LAST",
    "win_percentage DESC NULLS LAST",
    "created_at ASC"
  ].join(", ").freeze

  def self.sorted_by(column = "total_wins")
    column = column.presence || "total_wins"
    column = column.downcase
    return unless SORT_COLUMNS.include?(column)
    return order(Arel.sql(UNIVERSAL_RANK_ORDER)) if column == "total_wins"
    order(Arel.sql("#{column} DESC NULLS LAST"), name: :asc, created_at: :asc)
  end
end
