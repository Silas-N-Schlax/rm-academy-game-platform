module Rummy
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

    def as_json
      {
        "name" => name,
        "id" => id,
        "hand" => hand.map(&:as_json)
      }
    end

    def self.from_json(json)
      return if json.blank?
      Player.new(
        name: json["name"],
        id: json["id"],
        hand: json["hand"].map { |card| Card.from_json(card) }
      )
    end
  end
end
