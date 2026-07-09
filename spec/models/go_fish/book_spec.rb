require 'rails_helper'

RSpec.describe GoFish::Book, type: :model do
  describe '#to_s' do
    let(:book) { described_class.new('K') }
    it 'returns formatted string' do
      expected_string = 'king_of_hearts'
      expect(book.to_s).to eq expected_string
    end
  end
  describe '#as_json' do
    let(:book) { described_class.new('J') }
    let(:expected_hash) do
      {
        "rank" => 'J',
        "value" => 9
      }
    end
    it 'returns expected hash' do
      expect(book.as_json).to eq expected_hash
    end
  end

  describe '.from_json' do
    let(:book) { described_class.new('J') }
    it 'restores current state of the card' do
      json = book.as_json
      expect(GoFish::Book.from_json(json)).to have_attributes(
        rank: book.rank,
        value: book.value
      )
    end
  end
end
