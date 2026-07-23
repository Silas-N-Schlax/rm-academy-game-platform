module Rummy
  class Card < CardGame::Card
    SPELLED_RANKS = {
      "J" => "Jack",
      "Q" => "Queen",
      "K" => "King",
      "A" => "Ace"
    }.freeze

    def to_s
      "#{SPELLED_RANKS[rank] || rank}_of_#{suit}".downcase
    end

    def to_file_name
      to_s
    end

    def self.from_json(json)
      return [] if json.blank?
      super
    end
  end
end
