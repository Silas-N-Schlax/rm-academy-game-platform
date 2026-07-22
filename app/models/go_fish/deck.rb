module GoFish
  class Deck < CardGame::Deck
    def self.card_class
      GoFish::Card
    end
  end
end
