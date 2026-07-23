module Rummy
  class Player
    attr_accessor :hand, :has_melded
    attr_reader :name, :id

    def initialize(name:, id: 0, hand: [], has_melded: false)
      @name = name
      @id = id
      @hand = hand
      @has_melded = has_melded
    end

    def add_cards(cards)
      cards.each { |card| hand << card }
    end

    def remove_cards(cards)
      self.hand = hand - cards
    end

    def hand_pip_total
      hand.sum(&:pip_value)
    end

    def hand_size
      hand.size
    end

    def empty_hand?
      hand.empty?
    end

    def as_json
      {
        "name" => name,
        "id" => id,
        "hand" => hand.map(&:as_json),
        "has_melded" => has_melded
      }
    end

    def self.from_json(json)
      return if json.blank?
      Player.new(
        name: json["name"],
        id: json["id"],
        hand: json["hand"].map { |card| Card.from_json(card) },
        has_melded: json["has_melded"] || false
      )
    end
  end
end
