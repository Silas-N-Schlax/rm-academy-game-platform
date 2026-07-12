module CrazyEights
  class Card
    attr_accessor :wild_suit
    attr_reader :rank, :suit

    class InvalidRank < StandardError; end
    class InvalidSuit < StandardError; end

    RANKS = %w[2 3 4 5 6 7 8 9 10 J Q K A].freeze
    SUITS = %w[Spades Diamonds Hearts Clubs].freeze
    WILD_RANK = "8".freeze
    SPELLED_RANKS = {
      "J" => "Jack",
      "Q" => "Queen",
      "K" => "King",
      "A" => "Ace"
    }.freeze

    def initialize(rank, suit = "Spades", wild_suit = nil)
      raise InvalidRank unless RANKS.include?(rank)
      raise InvalidSuit unless SUITS.include?(suit)

      @rank = rank
      @suit = suit
      @wild_suit = wild_suit
    end

    def update_wild_suit(suit)
      return unless SUITS.include?(suit)
      self.wild_suit = suit
    end

    def to_s
      "#{SPELLED_RANKS[rank] || rank } of #{suit}"
    end

    def to_file_name
      to_s.gsub(" ", "_").downcase
    end

    def as_json
      {
        "rank" => rank,
        "suit" => suit,
        "wild_suit" => wild_suit
      }
    end

    def ==(other)
      rank == other.rank && suit == other.suit
    end

    def self.valid_rank?(rank)
      return false if rank.nil?
      RANKS.include?(rank.upcase)
    end

    def self.valid_suit?(suit)
      return false if suit.nil?
      SUITS.include?(suit.capitalize)
    end

    def self.value(rank)
      RANKS.index(rank)
    end

    def self.from_json(json)
      return [] if json.blank?
      Card.new(
        json["rank"], json["suit"], json["wild_suit"]
      )
    end
  end
end
