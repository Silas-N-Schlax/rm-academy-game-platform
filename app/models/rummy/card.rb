module Rummy
  class Card < CardGame::Card
    SPELLED_RANKS = {
      "J" => "Jack",
      "Q" => "Queen",
      "K" => "King",
      "A" => "Ace"
    }.freeze

    FACE_PIP_VALUE = 10
    ACE_PIP_VALUE = 1

    RUN_ORDER = %w[A 2 3 4 5 6 7 8 9 10 J Q K].freeze

    def to_s
      "#{SPELLED_RANKS[rank] || rank}_of_#{suit}".downcase
    end

    def to_file_name
      to_s
    end

    def pip_value
      return ACE_PIP_VALUE if rank == "A"
      return FACE_PIP_VALUE if %w[J Q K].include?(rank)
      rank.to_i
    end

    def run_position
      RUN_ORDER.index(rank)
    end

    def self.from_json(json)
      return if json.blank?
      super
    end
  end
end
