module CardGame
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

    private

    def generate_deck
      self.class.card_class::SUITS.flat_map do |suit|
        self.class.card_class::RANKS.map do |rank|
          self.class.card_class.new(rank, suit)
        end
      end
    end
  end
end
