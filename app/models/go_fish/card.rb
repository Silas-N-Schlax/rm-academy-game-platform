module GoFish
  class Card < CardGame::Card
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

    def to_s
      "#{SPELLED_RANKS[rank]}_of_#{suit}".downcase
    end

    def self.from_json(json)
      return [] if json.blank?
      super
    end
  end
end
