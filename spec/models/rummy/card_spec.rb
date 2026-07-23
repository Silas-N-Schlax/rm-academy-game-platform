require 'rails_helper'

RSpec.describe Rummy::Card, type: :model do
  it_behaves_like "a CardGame::Card"

  describe '#to_s' do
    it 'spells out face ranks' do
      expect(described_class.new('J', 'Hearts').to_s).to eq 'jack_of_hearts'
    end

    it 'keeps numeric ranks as-is' do
      expect(described_class.new('7', 'Clubs').to_s).to eq '7_of_clubs'
    end
  end

  describe '#to_file_name' do
    it 'matches the card image file name' do
      expect(described_class.new('Q', 'Spades').to_file_name).to eq 'queen_of_spades'
    end
  end

  describe '.from_json' do
    it 'returns nil for blank input, not an empty array' do
      expect(described_class.from_json(nil)).to be_nil
    end
  end

  describe '#pip_value' do
    it 'values an Ace as 1' do
      expect(described_class.new('A', 'Spades').pip_value).to eq 1
    end

    it 'values a numeric rank as its face value' do
      expect(described_class.new('7', 'Spades').pip_value).to eq 7
    end

    it 'values a King as 10' do
      expect(described_class.new('K', 'Spades').pip_value).to eq 10
    end

    it 'values a Queen as 10' do
      expect(described_class.new('Q', 'Spades').pip_value).to eq 10
    end

    it 'values a Jack as 10' do
      expect(described_class.new('J', 'Spades').pip_value).to eq 10
    end
  end

  describe '#run_position' do
    it 'places the Ace first (low), not last' do
      expect(described_class.new('A', 'Spades').run_position).to eq 0
    end

    it 'places the King last' do
      expect(described_class.new('K', 'Spades').run_position).to eq 12
    end

    it 'orders numeric ranks by face value' do
      expect(described_class.new('7', 'Spades').run_position).to eq 6
    end
  end
end
