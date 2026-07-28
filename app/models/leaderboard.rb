class Leaderboard < ApplicationRecord
  SORT_OPTIONS = {
    "total_games" => "Games",
    "total_wins" => "Won",
    "win_percentage" => "W/L",
    "seconds_played" => "Time Played"
  }.freeze

  SORT_COLUMNS = SORT_OPTIONS.keys.freeze

  def self.ransackable_attributes(_auth_object = nil)
    SORT_COLUMNS
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

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

  SORT_DIRECTIONS = %w[asc desc].freeze
  DEFAULT_SORT_DIRECTION = "desc"

  ORDER_CLAUSES = SORT_COLUMNS.index_with { |column|
    SORT_DIRECTIONS.index_with { |direction| "#{column} #{direction.upcase} NULLS LAST" }
  }.freeze

  def self.order_args_for(column, direction = DEFAULT_SORT_DIRECTION)
    column = column.presence || "total_wins"
    column = column.downcase
    direction = direction.presence&.downcase
    direction = DEFAULT_SORT_DIRECTION unless SORT_DIRECTIONS.include?(direction)
    return unless SORT_COLUMNS.include?(column)
    return [ Arel.sql(UNIVERSAL_RANK_ORDER) ] if column == "total_wins" && direction == DEFAULT_SORT_DIRECTION
    [ Arel.sql(ORDER_CLAUSES.fetch(column).fetch(direction)), { name: :asc, created_at: :asc } ]
  end

  def self.sorted_by(column = "total_wins", direction: DEFAULT_SORT_DIRECTION)
    args = order_args_for(column, direction)
    return unless args
    order(*args)
  end

  def self.stat_bounds(column)
    (minimum(column) || 0)..(maximum(column) || 0)
  end
end
