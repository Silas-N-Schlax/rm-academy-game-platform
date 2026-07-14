module CrazyEights
  class Pile
    attr_accessor :cards

    def initialize(cards: [])
      @cards = cards
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
      self.new(
        cards: json.map { |card| Card.from_json(card) }
      )
    end
  end
end
