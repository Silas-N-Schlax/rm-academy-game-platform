require 'rails_helper'

RSpec.describe CrazyEights::Pile, type: :model do
  let(:pile) { described_class.new(cards: [ CrazyEights::Card.new("J"), CrazyEights::Card.new("J"), CrazyEights::Card.new("J") ]) }

  describe '#cards_left' do
    it 'returns number of cards left' do
      expected_pile_size = 3
      expect(pile.cards_left).to eq expected_pile_size
    end
  end

  describe '#empty?' do
    it 'returns false if pile is full' do
      expect(pile.empty?).to be false
    end
    it 'returns true if pile is empty' do
      pile.cards = []
      expect(pile.empty?).to be true
    end
  end

  describe '#as_json' do
    let(:pile) { described_class.new(cards: [ GoFish::Card.new('J'), GoFish::Card.new('K') ]) }
    let(:expected_hash) do
      [
        {
          "rank" => 'J',
          "suit" => "Spades"
        },
        {
          "rank" => 'K',
          "suit" => "Spades"
        }
      ]
    end
    it 'returns expected hash' do
      expect(pile.as_json).to eq expected_hash
    end
  end

  describe '.from_json' do
    let(:pile) { described_class.new(cards: [ GoFish::Card.new('J'), GoFish::Card.new('K') ]) }
    it 'restores current state of the card' do
      json = pile.as_json
      expect(CrazyEights::Pile.from_json(json)).to have_attributes(
        cards: pile.cards
      )
    end
  end
end
