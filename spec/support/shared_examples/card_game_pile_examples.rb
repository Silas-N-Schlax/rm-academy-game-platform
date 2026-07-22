RSpec.shared_examples "a CardGame::Pile" do
  let(:pile) { described_class.new(cards: [ card_class.new('J'), card_class.new('J'), card_class.new('J') ]) }

  describe '#top_card' do
    it 'shows the top card and does not remove from the pile' do
      top_card = pile.cards.first
      expected_pile_size = 3
      expect(pile.top_card).to eq top_card
      expect(pile.cards_left).to eq expected_pile_size
    end

    context 'when the pile is empty' do
      before { pile.cards = [] }
      it 'returns nil' do
        expect(pile.top_card).to be_nil
      end
    end
  end

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
    let(:pile) { described_class.new(cards: [ card_class.new('J'), card_class.new('K') ]) }
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
    let(:pile) { described_class.new(cards: [ card_class.new('J'), card_class.new('K') ]) }
    it 'restores current state of the pile' do
      json = pile.as_json
      expect(described_class.from_json(json)).to have_attributes(
        cards: pile.cards
      )
    end

    it 'restores cards as the correct Card subclass' do
      json = pile.as_json
      expect(described_class.from_json(json).cards).to all(be_an_instance_of(card_class))
    end
  end
end
