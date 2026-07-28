class StatsPresenter
  Card = Struct.new(:title, :type, :total_games, :total_wins, :total_losses, :win_percentage,
                     :seconds_played, :average_game_duration, :first_played_at, keyword_init: true) do
    def slug
      type ? type.underscore.delete("_") : "overall"
    end
  end

  def initialize(user)
    @rows = Stat.for(user).index_by(&:type)
  end

  def overall
    build_card("Overall", nil)
  end

  def cards
    Game.new.valid_types.map { |type| build_card(type.underscore.titleize.sub(/\s*Game\z/, ""), type) }
  end

  private

  attr_reader :rows

  def build_card(title, type)
    row = rows[type]
    Card.new(title:, type:, **totals_for(row))
  end

  def totals_for(row)
    total_games = row&.total_games || 0
    total_wins = row&.total_wins || 0
    seconds_played = row&.seconds_played || 0
    { total_games:, total_wins:, total_losses: total_games - total_wins,
      win_percentage: ratio(total_wins, total_games) * 100, seconds_played:,
      average_game_duration: ratio(seconds_played, total_games), first_played_at: row&.first_played_at }
  end

  def ratio(numerator, total)
    return 0.0 if total.zero?

    numerator.to_f / total
  end
end
