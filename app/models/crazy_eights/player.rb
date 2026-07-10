module CrazyEights
  class Player
    attr_accessor :hand
    attr_reader :name, :id

    def initialize(name:, id: 0, hand: [])
      @name = name
      @id = id
      @hand = hand
    end


    def add_cards(cards)
      cards.each { |card| hand << card }
    end

    def take_card(rank, suit, wild_suit)
      find_by_rank = ->(card) { card.rank == rank && card.suit == suit }

      card_of_rank = hand.find(&find_by_rank)
      hand.delete_if(&find_by_rank)


      card_of_rank.wild_suit = wild_suit if card_of_rank && card_of_rank.rank == Card::WILD_RANK
      card_of_rank
    end

    def empty_hand?
      hand.empty?
    end

    def has_card?(rank, suit)
      hand.any? { |card| card.rank == rank && card.suit == suit }
    end

    def can_play?(top_card)
      return true if hand.any? { |card| card.rank == Card::WILD_RANK }
      return hand.any? { |card| card.rank == top_card.rank || card.suit == top_card.wild_suit } if top_card.wild_suit
      hand.any? { |card| card.rank == top_card.rank || card.suit == top_card.suit }
    end

    def hand_size
      hand.size
    end

    def sorted_hand
      hand.sort_by { |card| Card.value(card.rank) }
    end

    def as_json
      {
        "name" => name,
        "id" => id,
        "hand" => hand.map { |card| card.as_json }
      }
    end

    def self.from_json(json)
      return if json.blank?
      Player.new(
        name: json["name"],
        id: json["id"],
        hand: json["hand"].map { |card| Card.from_json(card) },
      )
    end
  end
end
