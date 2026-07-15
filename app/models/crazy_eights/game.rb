module CrazyEights
  class Game
    attr_accessor :players, :deck, :discard, :current_player_idx,
                  :results, :current_result, :wild_suit

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
      @wild_suit
    end

    def start
      deck.shuffle_deck
      deal
    end

    def play_card(rank:, suit:, wild_suit: nil)
      return winning_player if winner?
      return false unless valid_card?(rank, suit)

      set_wild_suit(wild_suit)

      card = current_player.take_card(rank, suit)
      discard.add_card(card)
      add_result(card: card)
      next_player_turn
    end

    def request_cards
      return winning_player if winner?
      top_card = discard.top_card
      return false if current_player.can_play?(top_card.rank, current_suit(top_card.suit))

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
      top_card = discard.top_card
      current_suit = wild_suit.nil? ? top_card.suit : wild_suit
      return false unless (rank == top_card.rank || rank == Card::WILD_RANK) || suit == current_suit
      return false unless current_player.has_card?(rank, suit)
      true
    end

    def as_json
      {
        "players" => players.map(&:as_json),
        "deck" => deck.as_json,
        "discard" => discard.as_json,
        "results" => results.map(&:as_json),
        "current_player_idx" => current_player_idx,
        "wild_suit" => wild_suit,
        "current_result" => current_result.as_json
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
      game = Game.new(
        players: json["players"].map { |player| Player.from_json(player) },
        deck: Deck.from_json(json["deck"]),
        discard: Discard.from_json(json["discard"]),
        results: json["results"].map { |result| TurnResult.from_json(result) },
        current_player_idx: json["current_player_idx"],
      )
      game.wild_suit = json["wild_suit"]
      game.current_result = TurnResult.from_json(json["current_result"])
      game
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

    def current_suit(card_suit)
     wild_suit.nil? ? card_suit : wild_suit
    end


    def add_result(card: nil, drawn_card: nil)
      current_result.card_played = card
      add_current_result_if_possible
      self.current_result = nil unless card.nil?
      current_result.add_to_drawn_card(drawn_card) unless drawn_card.nil?
    end

    def add_current_result_if_possible
      results << current_result unless results.include?(current_result)
    end

    def give_cards_to_player
      return next_player_turn if discard.cards_left == 1 && deck.empty?
      deck.add_cards(discard.all_but_top_card) if deck.empty?
      card = current_player.add_cards([ deck.take_top_card ])
      add_result(drawn_card: card.first)
      top_card = discard.top_card
      give_cards_to_player unless current_player.can_play?(top_card.rank, current_suit(top_card.suit))
    end

    def next_player_turn
      new_index = current_player_idx + 1
      first_player_idx = 0
      self.current_player_idx = new_index > players.size - 1 ? first_player_idx : new_index
    end

    def set_wild_suit(wild_suit)
      self.wild_suit = wild_suit if wild_suit
      self.wild_suit = nil if wild_suit.nil?
      current_result.wild_suit = wild_suit
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
