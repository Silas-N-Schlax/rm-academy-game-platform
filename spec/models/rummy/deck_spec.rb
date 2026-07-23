require 'rails_helper'

RSpec.describe Rummy::Deck, type: :model do
  let(:card_class) { Rummy::Card }

  it_behaves_like "a CardGame::Deck"
  it_behaves_like "a CardGame::Pile"

  describe '#add_cards' do
    let(:deck) { described_class.new(cards: []) }
    let(:cards) { [ Rummy::Card.new('9', 'Diamonds'), Rummy::Card.new('10', 'Diamonds') ] }

    it 'adds the given cards to the deck' do
      deck.add_cards(cards)
      expect(deck.cards_left).to eq 2
    end

    it 'shuffles the deck after adding' do
      allow(deck).to receive(:shuffle_deck)
      deck.add_cards(cards)
      expect(deck).to have_received(:shuffle_deck)
    end
  end
end
