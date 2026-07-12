module CrazyEights
  class Game
    attr_accessor :players, :deck, :discard, :current_player_idx, :results, :current_result

    SMALL_HAND = 5
    LARGE_HAND = 7
    SMALL_GAME_MAX_SIZE = 3
    LARGE_GAME_MAX_SIZE = 7
    DECK_SIZE = 52

    def current_result
      @current_result ||= TurnResult.new(current_player: current_player)
    end

    def initialize(players:, deck: Deck.new, discard: Discard.new, current_player_idx: 0, results: [])
      @players = players
      @deck = deck
      @discard = discard
      @current_player_idx = current_player_idx
      @results = results
    end

    def start
      deck.shuffle_deck
      deal
    end

    def play_card(rank:, suit:, wild_suit: nil)
      return winning_player if winner?
      return false unless valid_card?(rank, suit)

      card = current_player.take_card(rank, suit, wild_suit)
      discard.add_card(card)
      add_result(card: card)
      next_player_turn
    end

    def request_cards
      return winning_player if winner?
      return false if current_player.can_play?(discard.top_card)

      give_cards_to_player
    end

    def winner?
      players.any?(&:empty_hand?)
    end

    def winning_player
      players.find(&:empty_hand?)
    end

    def current_player
      players[current_player_idx]
    end

    def latest_result
      results.last
    end

    def find_player(id)
      players.find { |player| player.id == id }
    end


    def valid_card?(rank, suit)
      return false unless Card.valid_rank?(rank) && Card.valid_suit?(suit)
      return false unless current_player.has_card?(rank, suit)
      true
    end

    def as_json
      {
        "players" => players.map(&:as_json),
        "deck" => deck.as_json,
        "discard" => discard.as_json,
        "results" => results.map(&:as_json),
        "current_player_idx" => current_player_idx
      }
    end

    def self.create(players)
      game = Game.new(
        players: players.map { |player| Player.new(name: player.user.name, id: player.user_id) },
      )
      game.start
      game
    end

    def self.from_json(json)
      Game.new(
        players: json["players"].map { |player| Player.from_json(player) },
        deck: Deck.from_json(json["deck"]),
        discard: Discard.from_json(json["discard"]),
        results: json["results"].map { |result| TurnResult.from_json(result) },
        current_player_idx: json["current_player_idx"]
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


    def add_result(card: nil, drawn_card: nil)
      current_result.card_played = card
      results << current_result
      self.current_result = nil unless card.nil?
      current_result.add_to_drawn_card(drawn_card) unless drawn_card.nil?
    end

    def give_cards_to_player
      return next_player_turn if discard.cards_left == 1 && deck.empty?
      deck.add_cards(discard.all_but_top_card) if deck.empty?
      card = current_player.add_cards([ deck.take_top_card ])
      add_result(drawn_card: card.first)
      give_cards_to_player unless current_player.can_play?(discard.top_card)
    end

    def next_player_turn
      new_index = current_player_idx + 1
      first_player_idx = 0
      self.current_player_idx = new_index > players.size - 1 ? first_player_idx : new_index
    end

    def deal
      number_of_cards_to_deal.times do
        players.each do |player|
          player.add_cards([ deck.take_top_card ])
        end
      end
      discard.cards = [ deck.take_top_card ]
    end

    def number_of_cards_to_deal
      return LARGE_HAND if players.size <= SMALL_GAME_MAX_SIZE

      SMALL_HAND if players.size > SMALL_GAME_MAX_SIZE
    end
  end
end
