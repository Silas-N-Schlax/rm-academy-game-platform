class RummyPresenter
  attr_reader :game, :current_user, :turn, :turn_timer_seconds

  MINI_FAN_SIZE = 4

  def initialize(game, current_user, turn: nil, turn_timer_seconds: nil)
    @game = game
    @current_user = current_user
    @turn = turn
    @turn_timer_seconds = turn_timer_seconds
  end

  def name = game.name
  def game_type = "Rummy"
  def stock_count = implementation.deck.cards_left
  def turn_label = your_turn ? "Your Turn" : "#{current_player.name}'s Turn"
  def your_turn = current_user.id == current_player.id
  def awaiting_draw = your_turn && implementation.must_draw? && implementation.current_result.draw_source.blank?
  def your_name = your_player.name
  def your_flag = ""
  def discard_top = implementation.discard.top_card&.to_file_name
  def feed = []
  def error = turn_base_errors.first

  def hand
    your_player.hand.map { |card| { card: card.to_file_name, rank: card.rank, suit: card.suit, active: false } }
  end

  def opponents
    opponent_players.map { |player| opponent_attributes(player) }
  end

  def melds
    implementation.melds.map { |meld| { cards: meld.cards.map(&:to_file_name), full: meld.full? } }
  end

  def winner_name
    implementation.winner? ? implementation.winning_player.name : ""
  end

  def ranking
    return [] unless implementation.winner?
    implementation.ranking.each_with_index.map { |player, index| ranking_entry(player, index) }
  end

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
      name: player.name, hand_size: player.hand.size,
      mini_hand: Array.new([ player.hand.size, MINI_FAN_SIZE ].min),
      overflow: [ player.hand.size - MINI_FAN_SIZE, 0 ].max,
      melded: player.has_melded, flag: ""
    }
  end

  def ranking_entry(player, index)
    { place: index + 2, name: player.name, flag: "", pips: player.hand_pip_total }
  end
end
