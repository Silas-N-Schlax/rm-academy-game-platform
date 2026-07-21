module CardGame
  class Card
    attr_reader :rank, :suit

    class InvalidRank < StandardError; end
    class InvalidSuit < StandardError; end

    RANKS = %w[2 3 4 5 6 7 8 9 10 J Q K A].freeze
    SUITS = %w[Spades Diamonds Hearts Clubs].freeze

    def initialize(rank, suit = "Spades")
      raise InvalidRank unless RANKS.include?(rank)
      raise InvalidSuit unless SUITS.include?(suit)

      @rank = rank
      @suit = suit
    end

    def as_json
      {
        "rank" => rank,
        "suit" => suit
      }
    end

    def ==(other)
      rank == other.rank && suit == other.suit
    end

    def self.valid_rank?(rank)
      return false if rank.nil?
      RANKS.include?(rank.upcase)
    end

    def self.value(rank)
      RANKS.index(rank)
    end

    def self.from_json(json)
      self.new(json["rank"], json["suit"])
    end
  end
end
