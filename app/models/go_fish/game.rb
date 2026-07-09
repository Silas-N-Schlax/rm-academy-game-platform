module GoFish
  class Game
    attr_accessor :deck, :current_player_idx, :results, :players

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

    def run_turn(player_id, rank)
      return if winner || find_player(player_id).nil?

      handle_turn(player_id, rank)

      handle_players_without_cards(player_id)
      next_player_turn if last_current_player.empty_hand?
      skip_turn_if_needed if turn_skipped? && !winner
    end

    def turn_skipped?
      deck.empty? && current_player.empty_hand?
    end


    def winner
      winning_player if deck.empty? && players.all?(&:empty_hand?)
    end

    def next_player_turn
      new_index = current_player_idx + 1
      first_player_idx = 0
      self.current_player_idx = new_index > players.size - 1 ? first_player_idx : new_index
      nil
    end

    def current_player
      players[current_player_idx]
    end

    def find_player(id)
      players.find { |player| player.id == id }
    end

    def list_of_ranks(id)
      find_player(id).ranks
    end

    def list_of_players(current_id)
      all_players = []
      players.map do |player|
        all_players << player unless player.id == current_id
      end
      all_players
    end

    def latest_result
      results.last
    end

    def valid_player?(player_id)
      players.any? { |player| player.id == player_id } && player_id != current_player.id
    end

    def valid_rank?(rank)
      Card.valid_rank?(rank) && current_player.has_card?(rank)
    end

    def as_json
      {
        "players" => players.map { |player| player.as_json },
        "deck" => deck.as_json,
        "current_player_idx" => current_player_idx,
        "results" => results.map(&:as_json)
      }
    end

    def self.create(players)
      game = Game.new(
        players: players.map { |player| GoFish::Player.new(name: player.user.name, id: player.user_id) },
      )
      game.start
      game
    end

    def self.from_json(json)
      Game.new(
        players: json["players"].map { |player| GoFish::Player.from_json(player) },
        deck: GoFish::Deck.from_json(json["deck"]),
        current_player_idx: json["current_player_idx"],
        results: json["results"].map { |result| GoFish::TurnResult.from_json(result) }
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
    # ^ Private Methods!

    def handle_turn(player_name, rank)
      current_player = self.current_player
      player_in_question = find_player(player_name)
      cards = player_in_question.take_cards_of_rank(rank)

      current_player.add_cards(cards) unless cards.empty?
      fishing_card = go_fish(rank) if cards.empty?
      generate_turn_result(player_in_question, rank, cards, fishing_card, current_player, current_player.book_created)
    end

    def go_fish(rank)
      card = deck.top_card
      return next_player_turn if card.nil?

      current_player.add_cards([ card ])
      next_player_turn unless card.rank == rank
      card
    end

    def skip_turn_if_needed
      next_player_turn

      skip_turn_if_needed if turn_skipped?
    end

    def handle_players_without_cards(opponent)
      add_cards(current_player)
      add_cards(find_player(opponent))
    end

    def add_cards(player)
      return unless player.empty_hand? && !deck.empty?

      top_card = deck.top_card
      player.add_cards([ top_card ])
      latest_result.add_got_card_record(player, top_card)
    end

    def last_current_player
      latest_result.current_player
    end

    def deal
      number_of_cards_to_deal.times do
        players.each do |player|
          player.add_cards([ deck.top_card ])
        end
      end
    end

    def winning_player
      highest_value = players.map(&:books_size).max
      ties = players.select { |player| player.books_size == highest_value }
      ties.max_by { |player| player.highest_book.value }
    end

    def generate_turn_result(opponent, rank, cards, card_picked_up, current_player, created_book)
      results << GoFish::TurnResult.new(
        current_player: current_player, opponent: opponent,
        card_asked_for: rank, cards_taken: cards,
        card_picked_up: card_picked_up, goes_again: current_player.name == self.current_player.name,
        created_book: created_book
      )
    end

    def number_of_cards_to_deal
      return LARGE_HAND if players.size <= SMALL_GAME_MAX_SIZE

      SMALL_HAND if players.size > SMALL_GAME_MAX_SIZE
    end
  end
end
