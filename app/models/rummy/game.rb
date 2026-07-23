module Rummy
  class Game < CardGame::Engine
    attr_accessor :discard

    TWO_PLAYER_SIZE = 2
    SMALL_GROUP_MAX_SIZE = 4
    TWO_PLAYER_HAND = 10
    SMALL_GROUP_HAND = 7
    LARGE_GROUP_HAND = 6

    def initialize(players:, deck: Deck.new, discard: Discard.new, current_player_idx: 0, results: [])
      @players = players
      @deck = deck
      @discard = discard
      @current_player_idx = current_player_idx
      @results = results
    end

    def as_json
      {
        "players" => players.map(&:as_json),
        "deck" => deck.as_json,
        "discard" => discard.as_json,
        "current_player_idx" => current_player_idx
      }
    end

    def self.player_class = Rummy::Player

    def self.from_json(json)
      Game.new(
        players: json["players"].map { |player| Player.from_json(player) },
        deck: Deck.from_json(json["deck"]),
        discard: Discard.from_json(json["discard"]),
        current_player_idx: json["current_player_idx"]
      )
    end

    private_class_method :from_json
    private

    def after_deal
      discard.cards = [ deck.take_top_card ]
    end

    def number_of_cards_to_deal
      return TWO_PLAYER_HAND if players.size <= TWO_PLAYER_SIZE
      return SMALL_GROUP_HAND if players.size <= SMALL_GROUP_MAX_SIZE
      LARGE_GROUP_HAND
    end
  end
end
