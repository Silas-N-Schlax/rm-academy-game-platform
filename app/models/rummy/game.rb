module Rummy
  class Game < CardGame::Engine
    attr_accessor :discard, :melds, :current_result

    TWO_PLAYER_SIZE = 2
    SMALL_GROUP_MAX_SIZE = 4
    TWO_PLAYER_HAND = 10
    SMALL_GROUP_HAND = 7
    LARGE_GROUP_HAND = 6

    def initialize(players:, deck: Deck.new, discard: Discard.new, current_player_idx: 0, results: [], melds: [])
      @players = players
      @deck = deck
      @discard = discard
      @current_player_idx = current_player_idx
      @results = results
      @melds = melds
    end

    def current_result
      @current_result ||= TurnResult.new(current_player: current_player)
    end

    def must_draw?
      !(deck.empty? && discard.empty?)
    end

    def draw(source:)
      recycle_stock! if source == "stock" && deck.empty?
      card = source == "stock" ? deck.take_top_card : discard.take_top_card
      current_player.add_cards([ card ])
      current_result.draw_source = source
      current_result.card_drawn = card
    end

    def recycle_stock!
      current_result.recycled_stock = true
      deck.add_cards(discard.all_but_top_card || [])
    end

    def lay_down_meld(cards)
      return false unless Meld.valid?(cards)
      current_player.remove_cards(cards)
      melds << Meld.new(cards: cards)
      current_player.has_melded = true
      current_result.melds_laid_down << melds.last
      finish_turn if winner?
    end

    def lay_off(meld_index, cards)
      return false unless current_player.has_melded
      meld = melds[meld_index]
      return false if meld.nil? || !meld.accepts_sequence?(cards)
      current_player.remove_cards(cards)
      meld.cards += cards
      current_result.lay_offs << { meld: meld, cards: cards }
      finish_turn if winner?
    end

    def winner?
      players.any?(&:empty_hand?)
    end

    def winning_player
      players.find(&:empty_hand?)
    end

    def ranking
      players.reject(&:empty_hand?).sort_by(&:hand_pip_total)
    end

    def discard_card(card)
      current_player.remove_cards([ card ])
      discard.add_card(card)
      current_result.card_discarded = card
      finish_turn
    end

    def cards_from_ids(card_ids)
      card_ids.map { |id| find_card(id) }
    end

    def valid_move?(action:, source: nil, card_ids: [], meld_index: nil)
      cards = cards_from_ids(card_ids)
      return false if cards.any?(&:nil?)
      return valid_draw?(source) if action == "draw"
      return false unless draw_step_satisfied?
      valid_action_move?(action, cards, meld_index)
    end

    def as_json
      {
        "players" => players.map(&:as_json),
        "deck" => deck.as_json,
        "discard" => discard.as_json,
        "current_player_idx" => current_player_idx,
        "results" => results.map(&:as_json),
        "melds" => melds.map(&:as_json),
        "current_result" => current_result.as_json
      }
    end

    def self.player_class = Rummy::Player

    def self.from_json(json)
      game = Game.new(**from_json_attributes(json))
      game.current_result = TurnResult.from_json(json["current_result"])
      game
    end

    def self.from_json_attributes(json)
      {
        players: json["players"].map { |player| Player.from_json(player) },
        deck: Deck.from_json(json["deck"]),
        discard: Discard.from_json(json["discard"]),
        current_player_idx: json["current_player_idx"],
        results: json["results"].map { |result| TurnResult.from_json(result) },
        melds: json["melds"].map { |meld| Meld.from_json(meld) }
      }
    end

    private_class_method :from_json, :from_json_attributes
    private

    def finish_turn
      results << current_result unless results.include?(current_result)
      next_player_turn unless winner?
      self.current_result = nil
    end

    def find_card(id)
      rank, suit = id.split(":")
      current_player.hand.find { |card| card.rank == rank && card.suit == suit }
    end

    def draw_step_satisfied?
      current_result.draw_source.present? || !must_draw?
    end

    def valid_draw?(source)
      return false if current_result.draw_source.present? || !must_draw?
      return true if source == "discard"
      source == "stock" && (!deck.empty? || discard.cards_left >= 2)
    end

    def valid_action_move?(action, cards, meld_index)
      return Meld.valid?(cards) if action == "meld"
      return valid_layoff?(meld_index, cards) if action == "layoff"
      return valid_discard?(cards.first) if action == "discard"
      false
    end

    def valid_layoff?(meld_index, cards)
      return false unless current_player.has_melded
      meld = melds[meld_index]
      meld.present? && meld.accepts_sequence?(cards)
    end

    def valid_discard?(card)
      return true if current_player.hand == [ card ]
      !(current_result.draw_source == "discard" && current_result.card_drawn == card)
    end

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
