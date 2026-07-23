module Rummy
  class Deck < CardGame::Deck
    def self.card_class
      Rummy::Card
    end
  end
end
