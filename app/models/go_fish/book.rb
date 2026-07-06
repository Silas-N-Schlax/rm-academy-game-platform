module GoFish
  class Book
    attr_reader :rank, :value

    def initialize(rank)
      @rank = rank
      @value = Card.value(rank)
    end

    def to_s
      "#{Card::SPELLED_RANKS[rank].downcase}_of_hearts"
    end
  end
end
