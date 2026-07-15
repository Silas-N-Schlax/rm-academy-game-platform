module CrazyEights
  class TurnResult
    attr_reader :current_player
    attr_accessor :card_played, :cards_drawn, :wild_suit

    DREW_MESSAGE_BEGINNING = "drew a".freeze
    PLAYED_CARD_MESSAGE = "played a"
    PLAYED_WILD_MESSAGE = "played a wild! The suit is".freeze

    def initialize(current_player:, card_played: nil, cards_drawn: [], wild_suit: nil)
      @card_played = card_played
      @current_player = current_player
      @cards_drawn = cards_drawn
      @wild_suit = wild_suit
    end

    def messages_for_current
      return [ nil, played_message(title(true)) ] if cards_drawn.empty?
      return [ drew_message_for_current ] if card_played.nil?

      [ drew_message_for_current, played_message(title(true)) ]
    end

    def messages_for_all
      return [ nil, played_message(title) ] if cards_drawn.empty?
      return [ drew_message_for_all ] if card_played.nil? || card_played.is_a?(Array)

      [ drew_message_for_all, played_message(title) ]
    end

    def add_to_drawn_card(card)
      cards_drawn << card
    end

    def as_json
      {
        "card_played" => card_played.as_json,
        "current_player" => current_player.as_json,
        "cards_drawn" => cards_drawn.map(&:as_json),
        "wild_suit" => wild_suit
      }
    end

    def self.from_json(json)
      return if json.blank?
      TurnResult.new(
        card_played: Card.from_json(json["card_played"]),
        current_player: Player.from_json(json["current_player"]),
        cards_drawn: json["cards_drawn"].map { |card| Card.from_json(card) },
        wild_suit: json["wild_suit"]
      )
    end

    private

    def drew_message_for_current
      cards = cards_drawn.map(&:to_s)
      cards.insert(-2, "and") if cards.size > 1
      "#{title(true)} #{DREW_MESSAGE_BEGINNING} #{cards.join(", ")}".sub("and,", "and")
    end

    def drew_message_for_all
      "#{title} drew #{cards_drawn.size} cards"
    end

    def played_message(title)
      return "#{title} #{PLAYED_WILD_MESSAGE} #{wild_suit}" if wild_suit

      "#{title} #{PLAYED_CARD_MESSAGE} #{card_played}"
    end

    def title(current = false)
      return "You" if current

      current_player.name
    end
  end
end
