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
end
