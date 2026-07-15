module CrazyEights
  class Discard < Pile
    def add_card(card)
      return if card.nil?
      cards.unshift(card)
    end

    def all_but_top_card
      top_card = cards.shift
      rest_of_pile = cards
      self.cards = [ top_card ]
      rest_of_pile.empty? ? nil : rest_of_pile
    end
  end
end
