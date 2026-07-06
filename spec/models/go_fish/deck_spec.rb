require 'rails_helper'

RSpec.describe GoFish::Deck, type: :model do
  it 'should have 52 cards when created' do
    deck = described_class.new
    expected_deck_size = 52
    expect(deck.cards_left).to eq expected_deck_size
  end
  describe '#top_card' do
    let(:deck) { described_class.new }
    it 'takes the top card and removes from deck' do
      top_card = deck.cards.first
      expected_deck_size = 51
      expect(deck.top_card).to eq top_card
      expect(deck.cards_left).to eq expected_deck_size
    end
    context 'when the deck is empty' do
      before { deck.cards = [] }
      it 'returns nil' do
        expect(deck.top_card).to be_nil
      end
    end
  end
  describe '#shuffle_deck' do
    it 'shuffles the deck' do
      deck1 = described_class.new
      deck2 = described_class.new
      deck1.shuffle_deck

      expect(deck1.cards).to_not eq deck2.cards
    end
  end
  describe '#cards_left' do
    let(:deck) { described_class.new }
    it 'returns number of cards left' do
      expected_deck_size = 48
      deck.cards.shift(4)
      expect(deck.cards_left).to eq expected_deck_size
    end
  end
  describe '#empty?' do
    let(:deck) { described_class.new }
    it 'returns false if deck is full' do
      expect(deck.empty?).to be false
    end
    it 'returns true if deck is empty' do
      deck.cards = []
      expect(deck.empty?).to be true
    end
  end

  describe '#as_json' do
    let(:deck) { described_class.new }
    let(:expected_hash) do
      [
        {
          rank: 'J',
          suit: "Spades"
        },
        {
          rank: 'K',
          suit: "Spades"
        }
      ]
    end
    it 'returns expected hash' do
      deck.cards = [ GoFish::Card.new('J'), GoFish::Card.new('K') ]
      expect(deck.as_json).to eq expected_hash
    end
  end
end
