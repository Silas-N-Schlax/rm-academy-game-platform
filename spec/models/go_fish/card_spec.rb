require 'rails_helper'

RSpec.describe GoFish::Card, type: :model do
it 'has a rank, suit, and value' do
    card = described_class.new('A', 'Spades')
    expect(card.rank).to eq 'A'
    expect(card.suit).to eq 'Spades'
  end

  it 'cards of the same rank and suit are equal' do
    card1 = described_class.new('A', 'Spades')
    card2 = described_class.new('K', 'Spades')
    card3 = described_class.new('A', 'Spades')

    expect(card1).not_to eq card2
    expect(card1).to eq card3
  end

  it 'should allow valid ranks' do
    expect {
      described_class.new('15', 'Spades')
    }.to raise_error GoFish::Card::InvalidRank
  end

  it 'should allow valid suits' do
    expect {
      described_class.new('3', 'Bulkogi')
    }.to raise_error GoFish::Card::InvalidSuit
  end
  describe '#to_s' do
    it 'returns card as formatted string' do
      card = described_class.new('A')
      expected_output = 'ace_of_spades'
      expect(card.to_s).to eq expected_output
    end
    it 'returns card as a formatted string' do
      card = described_class.new('10')
      expected_output = '10_of_spades'
      expect(card.to_s).to eq expected_output
    end
  end
  describe '.valid_rank?' do
    it 'returns false if invalid rank' do
      rank = 'L'
      expect(described_class.valid_rank?(rank)).to be false
    end
    it 'returns true if valid rank' do
      rank = 'K'
      expect(described_class.valid_rank?(rank)).to be true
    end
  end
  describe '.value' do
    context 'when provided with an index' do
      it 'returns the index of the rank' do
        rank = 'K'
        expect(described_class.value(rank)).to be 11
      end
    end
  end
end
