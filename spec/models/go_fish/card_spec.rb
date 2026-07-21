require 'rails_helper'

RSpec.describe GoFish::Card, type: :model do
  it_behaves_like "a CardGame::Card"

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
  describe '.from_json' do
    context 'when the json is blank' do
      it 'returns an empty array' do
        expect(GoFish::Card.from_json(nil)).to eq []
      end
    end
  end
end
