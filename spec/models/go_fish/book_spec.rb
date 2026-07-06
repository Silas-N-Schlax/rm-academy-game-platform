require 'rails_helper'

RSpec.describe GoFish::Book, type: :model do
  describe '#to_s' do
    let(:book) { described_class.new('K') }
    it 'returns formatted string' do
      expected_string = 'king_of_hearts'
      expect(book.to_s).to eq expected_string
    end
  end
end
