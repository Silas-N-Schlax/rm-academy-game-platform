module GoFish
  class Card
    attr_reader :rank, :suit

    class InvalidRank < StandardError; end
    class InvalidSuit < StandardError; end

    RANKS = %w[2 3 4 5 6 7 8 9 10 J Q K A].freeze
    SUITS = %w[Spades Diamonds Hearts Clubs].freeze
    SPELLED_RANKS = {
      "2" => "2",
      "3" => "3",
      "4" => "4",
      "5" => "5",
      "6" => "6",
      "7" => "7",
      "8" => "8",
      "9" => "9",
      "10" => "10",
      "J" => "Jack",
      "Q" => "Queen",
      "K" => "King",
      "A" => "Ace"
    }.freeze

    def initialize(rank, suit = "Spades")
      raise InvalidRank unless RANKS.include?(rank)
      raise InvalidSuit unless SUITS.include?(suit)

      @rank = rank
      @suit = suit
    end

    def to_s
      "#{SPELLED_RANKS[rank]}_of_#{suit}".downcase
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
      RANKS.include?(rank.upcase)
    end

    def self.value(rank)
      RANKS.index(rank)
    end

    def self.from_json(json)
      return [] if json.blank?
      GoFish::Card.new(
        json["rank"], json["suit"]
      )
    end
  end
end
