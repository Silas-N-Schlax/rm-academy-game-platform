RSpec.shared_examples "a CardGame::Deck" do
  it 'should have 52 cards when created' do
    deck = described_class.new
    expected_deck_size = 52
    expect(deck.cards_left).to eq expected_deck_size
  end

  it 'generates cards of the correct Card subclass' do
    deck = described_class.new
    expect(deck.cards).to all(be_an_instance_of(card_class))
  end

  describe '#shuffle_deck' do
    it 'shuffles the deck' do
      deck1 = described_class.new
      deck2 = described_class.new
      deck1.shuffle_deck

      expect(deck1.cards).to_not eq deck2.cards
    end
  end

  describe '#take_top_card' do
    let(:deck) { described_class.new(cards: [ card_class.new('J'), card_class.new('J'), card_class.new('J') ]) }
    it 'takes the top card and removes from deck' do
      take_top_card = deck.cards.first
      expected_deck_size = 2
      expect(deck.take_top_card).to eq take_top_card
      expect(deck.cards_left).to eq expected_deck_size
    end

    context 'when the deck is empty' do
      before { deck.cards = [] }
      it 'returns nil' do
        expect(deck.take_top_card).to be_nil
      end
    end
  end
end
