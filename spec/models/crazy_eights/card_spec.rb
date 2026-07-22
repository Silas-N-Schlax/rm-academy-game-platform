require 'rails_helper'

RSpec.describe CrazyEights::Card, type: :model do
  it_behaves_like "a CardGame::Card"

  describe '#to_s' do
    it 'returns card as formatted string' do
      card = described_class.new('A')
      expected_output = 'Ace of Spades'
      expect(card.to_s).to eq expected_output
    end
    it 'returns card as a formatted string' do
      card = described_class.new('10')
      expected_output = '10 of Spades'
      expect(card.to_s).to eq expected_output
    end
  end

  describe '#to_file_name' do
    it 'returns card as formatted string' do
      card = described_class.new('A')
      expected_output = 'ace_of_spades'
      expect(card.to_file_name).to eq expected_output
    end
    it 'returns card as a formatted string' do
      card = described_class.new('10')
      expected_output = '10_of_spades'
      expect(card.to_file_name).to eq expected_output
    end
  end

  describe '.valid_suit' do
    it 'returns false if invalid rank' do
      suit = 'obi'
      expect(described_class.valid_suit?(suit)).to be false
    end
    it 'returns true if valid rank' do
      suit = 'Hearts'
      expect(described_class.valid_suit?(suit)).to be true
    end

    it 'returns false if rank is nil' do
      expect(described_class.valid_suit?(nil)).to be false
    end
  end

  describe '#update_wild_suit' do
    let(:card) { described_class.new('J') }
    it 'updates wild suit when suit is valid' do
      wild_suit = 'Spades'
      card.update_wild_suit(wild_suit)
      expect(card.wild_suit).to eq wild_suit
    end

    it 'returns nil if wild suit is invalid' do
      expect(card.update_wild_suit('Obi')).to be_nil
    end
  end

  describe '.from_json' do
    it 'restores wild_suit as nil for a freshly-dealt card' do
      card = described_class.new('J')
      json = card.as_json
      expect(CrazyEights::Card.from_json(json).wild_suit).to be_nil
    end

    context 'when the json is blank' do
      it 'returns nil' do
        expect(CrazyEights::Card.from_json(nil)).to be_nil
      end
    end
  end
end
