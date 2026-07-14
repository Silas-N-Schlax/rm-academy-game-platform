require 'rails_helper'

RSpec.describe CrazyEights::Deck, type: :model do
  it 'should have 52 cards when created' do
    deck = described_class.new
    expected_deck_size = 52
    expect(deck.cards_left).to eq expected_deck_size
  end

  describe '#shuffle_deck' do
    it 'shuffles the deck' do
      deck1 = described_class.new
      deck2 = described_class.new
      deck1.shuffle_deck

      expect(deck1.cards).to_not eq deck2.cards
    end
  end

   describe '#take_top_card' do
    let(:deck) { described_class.new(cards: [ CrazyEights::Card.new("J"), CrazyEights::Card.new("J"), CrazyEights::Card.new("J") ]) }
    it 'takes the top card and removes from the deck' do
      take_top_card = deck.cards.first
      expected_deck_size = 2
      expect(deck.take_top_card).to eq take_top_card
      expect(deck.cards_left).to eq expected_deck_size
    end

    context 'when the deck is empty' do
      before { deck.cards = [] }
      it 'returns nil' do
        expect(deck.take_top_card).to be_nil
      end
    end
  end

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
