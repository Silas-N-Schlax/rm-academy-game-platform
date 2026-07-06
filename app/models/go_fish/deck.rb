module GoFish
  class Deck
    attr_accessor :cards

    def initialize(cards: generate_deck)
      @cards = cards
    end

    def top_card
      cards.shift
    end

    def shuffle_deck
      new_deck = cards.dup.shuffle!
      shuffle_deck if new_deck == cards

      self.cards = new_deck
    end

    def cards_left
      cards.size
    end

    def empty?
      cards.empty?
    end

    def as_json
      cards.map { |card|  card.as_json }
    end

    def self.from_json(json)
      Deck.new(
        cards: json.map { |card| GoFish::Card.from_json(card) }
      )
    end

    private

    def generate_deck
      GoFish::Card::SUITS.flat_map do |suit|
        GoFish::Card::RANKS.map do |rank|
          GoFish::Card.new(rank, suit)
        end
      end
    end
  end
end
