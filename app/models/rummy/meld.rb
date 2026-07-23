module Rummy
  class Meld
    attr_accessor :cards

    MIN_RUN_SIZE = 3
    MAX_RUN_SIZE = Card::RUN_ORDER.size
    GROUP_SIZES = [ 3, 4 ].freeze
    GROUP_DESCRIPTIONS = { 3 => "three", 4 => "four" }.freeze

    def initialize(cards:)
      @cards = cards
    end

    def self.valid_group?(cards)
      return false unless GROUP_SIZES.include?(cards.size)
      cards.map(&:rank).uniq.size == 1 && cards.map(&:suit).uniq.size == cards.size
    end

    def self.valid_run?(cards)
      return false if cards.size < MIN_RUN_SIZE
      return false unless cards.map(&:suit).uniq.size == 1
      positions = cards.map(&:run_position).sort
      positions == (positions.first..positions.last).to_a && positions.uniq.size == cards.size
    end

    def self.valid?(cards)
      valid_group?(cards) || valid_run?(cards)
    end

    def accepts?(card)
      return accepts_for_group?(card) if group?
      accepts_for_run?(card)
    end

    def accepts_sequence?(new_cards)
      applies_in_order?(new_cards.sort_by(&:run_position)) ||
        applies_in_order?(new_cards.sort_by(&:run_position).reverse)
    end

    def description
      return "#{GROUP_DESCRIPTIONS[cards.size]} #{spelled_rank(cards.first.rank)}s" if group?
      "run of #{sorted_cards.map(&:rank).join('-')} of #{cards.first.suit}"
    end

    def group?
      self.class.valid_group?(cards)
    end

    def full?
      group? ? cards.size == GROUP_SIZES.max : cards.size == MAX_RUN_SIZE
    end

    def as_json
      cards.map(&:as_json)
    end

    def self.from_json(json)
      new(cards: json.map { |card| Card.from_json(card) })
    end

    private

    def sorted_cards
      cards.sort_by(&:run_position)
    end

    def accepts_for_group?(card)
      cards.size < GROUP_SIZES.max && card.rank == cards.first.rank && cards.none? { |c| c.suit == card.suit }
    end

    def accepts_for_run?(card)
      return false unless card.suit == cards.first.suit
      [ sorted_cards.first.run_position - 1, sorted_cards.last.run_position + 1 ].include?(card.run_position)
    end

    def applies_in_order?(ordered_cards)
      scratch = self.class.new(cards: cards.dup)
      ordered_cards.all? do |card|
        next false unless scratch.accepts?(card)
        scratch.cards += [ card ]
        true
      end
    end

    def spelled_rank(rank)
      Card::SPELLED_RANKS[rank] || rank
    end
  end
end
