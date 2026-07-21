require 'rails_helper'

RSpec.describe CrazyEights::Deck, type: :model do
  let(:card_class) { CrazyEights::Card }

  it_behaves_like "a CardGame::Deck"
  it_behaves_like "a CardGame::Pile"

  describe '#add_cards' do
    let(:deck) { described_class.new(cards: []) }
    let(:card1) { CrazyEights::Card.new('A', 'Spades') }
    let(:card2) { CrazyEights::Card.new('K', 'Spades') }
    context 'when deck has no cards' do
      it 'adds cards to bottom in correct orders' do
        expected_deck_size = 2
        deck.add_cards([ card1, card2 ])
        expect(deck.cards_left).to eq expected_deck_size
      end
    end
  end
end
