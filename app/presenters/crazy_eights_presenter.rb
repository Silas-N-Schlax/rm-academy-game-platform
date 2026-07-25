class CrazyEightsPresenter
  attr_reader :game, :current_user, :turn, :turn_timer_seconds

  DEFAULT_AVATAR_URL = "/default_avatar.png"
  SECONDS_PER_MINUTE = 60
  SECONDS_PER_HOUR = 3600
  SECONDS_PER_DAY = 86400
  RECENT_CUTOFF_DAYS = 30

  def initialize(game, current_user, turn: nil, turn_timer_seconds: nil)
    @game = game
    @current_user = current_user
    @turn = turn
    @turn_timer_seconds = turn_timer_seconds
  end

  def name = game.name
  def game_type = "Crazy Eights"
  def stock_count = implementation.deck.cards_left
  def discard_top = implementation.discard.top_card&.to_file_name
  def wild_suit = implementation.wild_suit
  def turn_label = your_turn ? "Your Turn" : "#{current_player.name}'s Turn"
  def your_turn = current_user.id == current_player.id
  def hand_disabled = !your_turn
  def your_name = your_player.name
  def error = turn_base_errors.first
  def feed = implementation.results.reverse.map { |result| feed_turn(result) }

  def action_notice
    latest_turn_lines.last&.fetch(:text) || ""
  end

  def hand
    your_player.hand.map { |card| { card: card.to_file_name, rank: card.rank, suit: card.suit } }
  end

  def opponents
    opponent_players.map { |player| opponent_attributes(player) }
  end

  def winner_name
    implementation.winner? ? implementation.winning_player.name : ""
  end

  def ranking
    return [] unless implementation.winner?
    implementation.ranking.reject { |player| player == implementation.winning_player }
      .each_with_index.map { |player, index| ranking_entry(player, index) }
  end

  def ranking_subtitle = "Ranked by fewest cards left"

  private

  def turn_base_errors
    return [] if turn.nil?
    turn.errors[:base]
  end

  def latest_turn_lines
    feed.first ? feed.first[:lines] : []
  end

  def implementation = @implementation ||= game.game_state
  def your_player = @your_player ||= implementation.find_player(current_user.id)
  def current_player = @current_player ||= implementation.current_player

  def opponent_players
    @opponent_players ||= implementation.players.reject { |player| player.id == current_user.id }
  end

  def opponent_attributes(player)
    {
      id: player.id, name: player.name, hand_size: player.hand_size,
      last_action: last_action_for(player),
      current_turn: player.id == current_player.id, avatar_url: DEFAULT_AVATAR_URL
    }
  end

  def last_action_for(player)
    result = implementation.results.reverse.find { |turn_result| turn_result.current_player.id == player.id }
    result&.feed_lines(current_user.id)&.last&.fetch(:text) || ""
  end

  def ranking_entry(player, index)
    { place: index + 2, name: player.name, flag: "", cards_left: player.hand_size, score: "#{player.hand_size} card#{"s" if player.hand_size != 1} left" }
  end

  def feed_turn(result)
    {
      actor: result.actor_label(current_user.id),
      time: relative_time(result.occurred_at),
      lines: result.feed_lines(current_user.id)
    }
  end

  def relative_time(occurred_at)
    return "" if occurred_at.nil?
    seconds = (Time.current - occurred_at).to_i
    return "Just now" if seconds < SECONDS_PER_MINUTE
    return "#{count_with_unit(seconds / SECONDS_PER_MINUTE, "min")} ago" if seconds < SECONDS_PER_HOUR
    return "#{count_with_unit(seconds / SECONDS_PER_HOUR, "hour")} ago" if seconds < SECONDS_PER_DAY
    relative_day(seconds)
  end

  def relative_day(seconds)
    days = seconds / SECONDS_PER_DAY
    return "#{count_with_unit(days, "day")} ago" if days < RECENT_CUTOFF_DAYS
    "A while ago"
  end

  def count_with_unit(count, unit)
    "#{count} #{unit}#{"s" if count != 1}"
  end
end
