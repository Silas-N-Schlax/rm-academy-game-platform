module Rummy
  class Discard < CardGame::Pile
    def self.card_class
      Rummy::Card
    end
  end
end
