module CrazyEights
  class Deck < Pile
    def initialize(cards: generate_deck)
      @cards = cards
    end

    def shuffle_deck
      new_deck = cards.dup.shuffle!
      shuffle_deck if new_deck == cards

      self.cards = new_deck
    end

    def take_top_card
      cards.shift
    end

    def add_cards(new_cards)
      new_cards.each { |card| cards << card }
      shuffle_deck
    end

    private

    def generate_deck
      Card::SUITS.flat_map do |suit|
        Card::RANKS.map do |rank|
          Card.new(rank, suit)
        end
      end
    end
  end
end
