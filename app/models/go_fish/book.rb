module GoFish
  class Book
    attr_reader :rank, :value

    def initialize(rank, value = Card.value(rank))
      @rank = rank
      @value = value
    end

    def to_s
      "#{Card::SPELLED_RANKS[rank].downcase}_of_hearts"
    end

    def as_json
      {
        "rank" => rank,
        "value" => value
      }
    end

    def self.from_json(json)
      return [] if json.blank?
      GoFish::Book.new(
        json["rank"], json["value"]
      )
    end
  end
end
