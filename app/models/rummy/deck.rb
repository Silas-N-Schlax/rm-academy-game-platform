module Rummy
  class Deck < CardGame::Deck
    def self.card_class
      Rummy::Card
    end

    def add_cards(new_cards)
      new_cards.each { |card| cards << card }.reverse
    end
  end
end
