module CardGame
  class Engine
    attr_accessor :deck, :current_player_idx, :results, :players

    SMALL_HAND = 5
    LARGE_HAND = 7

    def start
      deck.shuffle_deck
      deal
    end

    def current_player
      players[current_player_idx]
    end

    def find_player(id)
      players.find { |player| player.id == id }
    end

    def latest_result
      results.last
    end

    def next_player_turn
      new_index = current_player_idx + 1
      first_player_idx = 0
      self.current_player_idx = new_index > players.size - 1 ? first_player_idx : new_index
      nil
    end

    def self.create(players)
      game = self.new(
        players: players.sort_by(&:id).map { |player| player_class.new(name: player.user.name, id: player.user_id) }
      )
      game.start
      game
    end

    def self.load(json)
      return nil if json.blank?
      from_json(json)
    end

    def self.dump(game)
      game.as_json
    end

    def self.player_class = raise NotImplementedError, "#{self} must implement .player_class"

    private

    def deal
      number_of_cards_to_deal.times do
        players.each { |player| player.add_cards([ deck.take_top_card ]) }
      end
      after_deal
    end

    def after_deal; end

    def number_of_cards_to_deal
      return LARGE_HAND if players.size <= self.class::SMALL_GAME_MAX_SIZE

      SMALL_HAND if players.size > self.class::SMALL_GAME_MAX_SIZE
    end
  end
end
