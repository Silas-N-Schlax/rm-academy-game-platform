module GoFish
  class Player
    attr_accessor :hand, :books
    attr_reader :name, :id

    def initialize(name, id = 0)
      @name = name
      @id = id
      @hand = []
      @books = []
    end

    def add_cards(cards)
      cards.each { |card| hand << card }
      create_book_if_possible
    end

    def take_cards_of_rank(rank)
      find_by_rank = ->(card) { card.rank == rank }

      cards_of_rank = hand.select(&find_by_rank)
      hand.delete_if(&find_by_rank)

      cards_of_rank
    end

    def empty_hand?
      hand.empty?
    end


    def hand_size
      hand.size
    end

    def books_size
      books.size
    end

    private

    def create_book_if_possible
      hand.group_by(&:rank).each do |group|
        card_group = group.last
        create_book_and_remove_cards(group.first) if card_group.length == 4
      end
      books.last
    end

    def create_book_and_remove_cards(book_rank)
      books << GoFish::Book.new(book_rank)
      take_cards_of_rank(book_rank)
    end
  end
end
