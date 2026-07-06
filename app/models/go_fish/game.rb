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

    def self.create(players)
      game = Game.new(
        players: players.map { |player| GoFish::Player.new(player.user.name, player.id) },
      )
      game.start
      game
    end

    def self.load(game_state)
      # takes in game_state and loads the objects
      # sends back the object
    end

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
