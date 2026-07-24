class GoFishPresenter
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
  def game_type = "Go Fish"
  def stock_count = implementation.deck.cards_left
  def turn_label = your_turn ? "Your Turn" : "#{current_player.name}'s Turn"
  def your_turn = current_user.id == current_player.id
  def hand_disabled = !your_turn
  def your_name = your_player.name
  def error = turn_base_errors.first
  def feed = implementation.results.reverse.map { |result| feed_turn(result) }

  def hand
    your_player.hand.map { |card| { card: card.to_file_name, rank: card.rank, suit: card.suit } }
  end

  def your_books
    your_player.books.map(&:to_s)
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

  def ranking_subtitle = "Ranked by books, most first"

  private

  def turn_base_errors
    return [] if turn.nil?
    turn.errors[:base]
  end

  def implementation = @implementation ||= game.game_state
  def your_player = @your_player ||= implementation.find_player(current_user.id)
  def current_player = @current_player ||= implementation.current_player

  def opponent_players
    @opponent_players ||= implementation.players.reject { |player| player.id == current_user.id }
  end

  def opponent_attributes(player)
    {
      id: player.id, name: player.name, hand_size: player.hand_size, book_count: player.books_size,
      hand_backs: Array.new(player.hand_size), books: player.books.map(&:to_s),
      current_turn: player.id == current_player.id, avatar_url: DEFAULT_AVATAR_URL
    }
  end

  def ranking_entry(player, index)
    { place: index + 2, name: player.name, flag: "", books: player.books_size, score: "#{player.books_size} books" }
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
