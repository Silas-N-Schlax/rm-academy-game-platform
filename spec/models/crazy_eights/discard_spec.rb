require 'rails_helper'

RSpec.describe CrazyEights::Discard, type: :model do
  describe '#add_card' do
    let(:discard_pile) { described_class.new(cards: [ CrazyEights::Card.new("J") ]) }
    it 'adds card to top of discard pile' do
      card = CrazyEights::Card.new('10')
      discard_pile.add_card(card)
      expect(discard_pile.top_card).to eq card
    end

    it 'returns nil if card is nil' do
      expect(discard_pile.add_card(nil)).to be_nil
    end
  end

  describe '#all_but_top_card' do
    let(:discard_pile) { described_class.new(cards: [ CrazyEights::Card.new("J"), CrazyEights::Card.new("10"), CrazyEights::Card.new("9") ]) }
    it 'returns array of all but the top card' do
      expected_pile_size = 2
      expected_discard_pile_size = 1
      expect(discard_pile.all_but_top_card.size).to eq expected_pile_size
      expect(discard_pile.cards_left).to eq expected_discard_pile_size
    end

    it 'returns nil if only 1 card' do
      discard_pile.cards = [ CrazyEights::Card.new('J') ]
      expect(discard_pile.all_but_top_card).to be_nil
    end
  end
end
