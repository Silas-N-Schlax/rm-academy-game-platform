class Leaderboard < ApplicationRecord
  SORT_OPTIONS = {
    "total_games" => "Games",
    "total_wins" => "Won",
    "win_percentage" => "W/L",
    "seconds_played" => "Time Played"
  }.freeze

  SORT_COLUMNS = SORT_OPTIONS.keys.freeze

  def self.sorted_by(column = "total_wins")
    column = column.presence || "total_wins"
    column = column.downcase
    return unless SORT_COLUMNS.include?(column)
    order(Arel.sql("#{column} DESC NULLS LAST"), name: :asc)
  end
end
