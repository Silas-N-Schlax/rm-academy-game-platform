RSpec.shared_examples "a CardGame::Card" do
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

  it 'raises InvalidRank for an invalid rank' do
    expect {
      described_class.new('15', 'Spades')
    }.to raise_error described_class::InvalidRank
  end

  it 'raises InvalidSuit for an invalid suit' do
    expect {
      described_class.new('3', 'Bulkogi')
    }.to raise_error described_class::InvalidSuit
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

    it 'returns false if rank is nil' do
      expect(described_class.valid_rank?(nil)).to be false
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

  describe '#as_json' do
    let(:card) { described_class.new('J') }
    let(:expected_hash) do
      {
        "rank" => 'J',
        "suit" => 'Spades'
      }
    end
    it 'returns expected hash' do
      expect(card.as_json).to eq expected_hash
    end
  end

  describe '.from_json' do
    let(:card) { described_class.new('J') }
    it 'restores current state of the card' do
      json = card.as_json
      expect(described_class.from_json(json)).to have_attributes(
        rank: card.rank,
        suit: card.suit
      )
    end
  end
end
