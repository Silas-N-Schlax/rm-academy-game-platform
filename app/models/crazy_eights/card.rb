module CrazyEights
  class Card < CardGame::Card
    attr_accessor :wild_suit

    WILD_RANK = "8".freeze
    SPELLED_RANKS = {
      "J" => "Jack",
      "Q" => "Queen",
      "K" => "King",
      "A" => "Ace"
    }.freeze

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

    def self.valid_suit?(suit)
      return false if suit.nil?
      SUITS.include?(suit.capitalize)
    end

    def self.from_json(json)
      return if json.blank?
      super
    end
  end
end
