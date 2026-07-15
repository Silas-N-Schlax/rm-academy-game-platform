module GoFish
  class TurnResult
    attr_accessor :current_player, :opponent, :cards_taken,
                    :rank_asked_for, :card_picked_up,
                    :goes_again, :created_book

    def initialize(current_player:, opponent:, cards_taken:, rank_asked_for:, card_picked_up:, goes_again:, created_book: nil)
      @current_player = current_player
      @opponent = opponent
      @cards_taken = cards_taken
      @rank_asked_for = rank_asked_for&.upcase
      @card_picked_up = card_picked_up
      @goes_again = goes_again
      @created_book = created_book
    end

    def got_card
      @got_card ||= []
    end

    def question(id)
      [ "#{current_or_opponent(id)} asked ", opponent.name, " for any ", rank_asked_for, "s" ]
    end

    def answer
      return "#{opponent.name} had #{cards_taken.size} #{rank_asked_for}s" unless cards_taken.empty?

      "Go Fish: #{opponent.name} didn't have any #{rank_asked_for}s"
    end

    def go_fish(id)
      return go_fish_current if id == current_player.id

      go_fish_all
    end

    def book_created(id)
      return if created_book.nil?

      "#{current_or_opponent(id)} created a book of #{created_book.rank}s"
    end

    def got_card_message(id)
      message_ary = []
      got_card.map do |record|
        next message_ary << "You ran out of cards, you drew a #{record.last.rank}" if record.first.id == id

        message_ary << "#{record.first.name} ran out of cards, they drew a card"
      end
      message_ary
    end

    def add_got_card_record(player, card)
      got_card << [ player, card ]
    end

    def as_json
      {
        "current_player" => current_player.as_json,
        "opponent" => opponent.as_json,
        "cards_taken" => cards_taken.map(&:as_json),
        "rank_asked_for" => rank_asked_for,
        "card_picked_up" => card_picked_up.as_json,
        "goes_again" => goes_again,
        "created_book" => created_book.as_json,
        "got_card" => got_card
      }
    end

    def self.from_json(json)
      result = GoFish::TurnResult.new(
        current_player: GoFish::Player.from_json(json["current_player"]),
        opponent: GoFish::Player.from_json(json["opponent"]),
        cards_taken: json["cards_taken"].map { |card| GoFish::Card.from_json(card) },
        rank_asked_for: json["rank_asked_for"],
        card_picked_up: GoFish::Card.from_json(json["card_picked_up"]),
        goes_again: json["goes_again"],
      )
      json["got_card"].map { |element| result.add_got_card_record(GoFish::Player.from_json(element[0]), GoFish::Card.from_json(element[1])) } if json["got_card"]
      result
    end

    private

    def current_or_opponent(id)
      return "You" if current_player.id == id

      current_player.name
    end

    def go_fish_current
      return if card_picked_up.nil? || (card_picked_up.is_a?(Array) && card_picked_up.empty?)

      "You drew a #{card_picked_up.rank} of #{card_picked_up.suit} #{got_what_wanted_current}"
    end

    def go_fish_all
      return if card_picked_up.nil? || (card_picked_up.is_a?(Array) && card_picked_up.empty?)

      "#{current_player.name} drew a card #{got_what_wanted_all}"
    end

    def got_what_wanted_current
      "and #{goes_again ? 'get' : 'do not get'} to go again"
    end

    def got_what_wanted_all
      "and #{goes_again ? 'gets' : 'does not get'} to go again"
    end

    def bot_message(name)
      return go_fish_current if current_player.name == name

      go_fish_all
    end

    def went_fishing?
      return true if card_picked_up

      false
    end
  end
end
