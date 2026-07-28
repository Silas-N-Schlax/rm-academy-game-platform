class Leaderboard < ApplicationRecord
  SORT_COLUMNS = %w[total_wins total_games win_percentage seconds_played].freeze

  def self.sorted_by(column = "total_wins")
    column = column.downcase
    return unless SORT_COLUMNS.include?(column)
    order(Arel.sql("#{column} DESC NULLS LAST"), name: :asc)
  end
end
