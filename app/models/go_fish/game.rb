module GoFish
  class Game
    attr_accessor :players, :deck, :current_player_idx, :results

    SMALL_HAND = 5
    LARGE_HAND = 7
    SMALL_GAME_MAX_SIZE = 2
    LARGE_GAME_MAX_SIZE = 6
    DECK_SIZE = 52

    def initialize(players:, deck: GoFish::Deck.new, current_player_idx: 0, results: [])
      @players = players
      @deck = deck
      @current_player_idx = current_player_idx
      @results = results
    end

    def start
      deck.shuffle_deck
      deal
    end

    def as_json
      {
        "players" => players.map { |player| player.as_json },
        "deck" => deck.as_json,
        "current_player_idx" => current_player_idx,
        "results" => results
      }
    end

    def self.create(players)
      game = Game.new(
        players: players.map { |player| GoFish::Player.new(name: player.user.name, id: player.id) },
      )
      game.start
      game
    end

    def self.from_json(json)
      Game.new(
        players: json["players"].map { |player| GoFish::Player.from_json(player) },
        deck: GoFish::Deck.from_json(json["deck"]),
        current_player_idx: json["current_player_idx"],
        results: json["results"]
      )
    end

    def self.load(json)
      return nil if json.blank?
      self.from_json(json)
    end

    def self.dump(game)
      game.as_json
    end

    private_class_method :from_json
    private

    def deal
      number_of_cards_to_deal.times do
        players.each do |player|
          player.add_cards([ deck.top_card ])
        end
      end
    end

    def number_of_cards_to_deal
      return LARGE_HAND if players.size <= SMALL_GAME_MAX_SIZE

      SMALL_HAND if players.size > SMALL_GAME_MAX_SIZE
    end
  end
end
