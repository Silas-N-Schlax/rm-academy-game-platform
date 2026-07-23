require 'rails_helper'

RSpec.describe Rummy::Meld, type: :model do
  describe '.valid_group?' do
    it 'returns true for 3 cards of the same rank with distinct suits' do
      cards = [ Rummy::Card.new('7', 'Spades'), Rummy::Card.new('7', 'Hearts'), Rummy::Card.new('7', 'Diamonds') ]
      expect(described_class.valid_group?(cards)).to be true
    end

    it 'returns true for 4 cards of the same rank with distinct suits' do
      cards = [
        Rummy::Card.new('7', 'Spades'), Rummy::Card.new('7', 'Hearts'),
        Rummy::Card.new('7', 'Diamonds'), Rummy::Card.new('7', 'Clubs')
      ]
      expect(described_class.valid_group?(cards)).to be true
    end

    it 'returns false when fewer than 3 cards' do
      cards = [ Rummy::Card.new('7', 'Spades'), Rummy::Card.new('7', 'Hearts') ]
      expect(described_class.valid_group?(cards)).to be false
    end

    it 'returns false when the ranks differ' do
      cards = [ Rummy::Card.new('7', 'Spades'), Rummy::Card.new('7', 'Hearts'), Rummy::Card.new('8', 'Diamonds') ]
      expect(described_class.valid_group?(cards)).to be false
    end

    it 'returns false when two cards share a suit' do
      cards = [ Rummy::Card.new('7', 'Spades'), Rummy::Card.new('7', 'Spades'), Rummy::Card.new('7', 'Diamonds') ]
      expect(described_class.valid_group?(cards)).to be false
    end
  end

  describe '.valid_run?' do
    it 'returns true for 3 consecutive same-suit cards' do
      cards = [ Rummy::Card.new('5', 'Hearts'), Rummy::Card.new('6', 'Hearts'), Rummy::Card.new('7', 'Hearts') ]
      expect(described_class.valid_run?(cards)).to be true
    end

    it 'returns true regardless of the order the cards are given in' do
      cards = [ Rummy::Card.new('7', 'Hearts'), Rummy::Card.new('5', 'Hearts'), Rummy::Card.new('6', 'Hearts') ]
      expect(described_class.valid_run?(cards)).to be true
    end

    it 'treats the Ace as low, allowing A-2-3' do
      cards = [ Rummy::Card.new('A', 'Hearts'), Rummy::Card.new('2', 'Hearts'), Rummy::Card.new('3', 'Hearts') ]
      expect(described_class.valid_run?(cards)).to be true
    end

    it 'rejects a wraparound run like Q-K-A' do
      cards = [ Rummy::Card.new('Q', 'Hearts'), Rummy::Card.new('K', 'Hearts'), Rummy::Card.new('A', 'Hearts') ]
      expect(described_class.valid_run?(cards)).to be false
    end

    it 'returns false when the cards are not consecutive' do
      cards = [ Rummy::Card.new('5', 'Hearts'), Rummy::Card.new('6', 'Hearts'), Rummy::Card.new('8', 'Hearts') ]
      expect(described_class.valid_run?(cards)).to be false
    end

    it 'returns false when the suits differ' do
      cards = [ Rummy::Card.new('5', 'Hearts'), Rummy::Card.new('6', 'Hearts'), Rummy::Card.new('7', 'Spades') ]
      expect(described_class.valid_run?(cards)).to be false
    end

    it 'returns false when fewer than 3 cards' do
      cards = [ Rummy::Card.new('5', 'Hearts'), Rummy::Card.new('6', 'Hearts') ]
      expect(described_class.valid_run?(cards)).to be false
    end
  end

  describe '.valid?' do
    it 'returns true for a valid group' do
      cards = [ Rummy::Card.new('7', 'Spades'), Rummy::Card.new('7', 'Hearts'), Rummy::Card.new('7', 'Diamonds') ]
      expect(described_class.valid?(cards)).to be true
    end

    it 'returns true for a valid run' do
      cards = [ Rummy::Card.new('5', 'Hearts'), Rummy::Card.new('6', 'Hearts'), Rummy::Card.new('7', 'Hearts') ]
      expect(described_class.valid?(cards)).to be true
    end

    it 'returns false when neither a valid group nor a valid run' do
      cards = [ Rummy::Card.new('5', 'Hearts'), Rummy::Card.new('9', 'Clubs'), Rummy::Card.new('2', 'Diamonds') ]
      expect(described_class.valid?(cards)).to be false
    end
  end

  describe '#accepts?' do
    context 'for a group meld' do
      let(:meld) do
        described_class.new(cards: [ Rummy::Card.new('7', 'Spades'), Rummy::Card.new('7', 'Hearts'), Rummy::Card.new('7', 'Diamonds') ])
      end

      it 'accepts the remaining suit of the same rank' do
        expect(meld.accepts?(Rummy::Card.new('7', 'Clubs'))).to be true
      end

      it 'rejects a different rank' do
        expect(meld.accepts?(Rummy::Card.new('8', 'Clubs'))).to be false
      end

      it 'rejects a suit already in the meld' do
        expect(meld.accepts?(Rummy::Card.new('7', 'Spades'))).to be false
      end

      it 'rejects a 5th card once the group already has 4' do
        full_meld = described_class.new(cards: [
          Rummy::Card.new('7', 'Spades'), Rummy::Card.new('7', 'Hearts'),
          Rummy::Card.new('7', 'Diamonds'), Rummy::Card.new('7', 'Clubs')
        ])
        expect(full_meld.accepts?(Rummy::Card.new('7', 'Spades'))).to be false
      end
    end

    context 'for a run meld' do
      let(:meld) do
        described_class.new(cards: [ Rummy::Card.new('5', 'Hearts'), Rummy::Card.new('6', 'Hearts'), Rummy::Card.new('7', 'Hearts') ])
      end

      it 'accepts a card extending the low end' do
        expect(meld.accepts?(Rummy::Card.new('4', 'Hearts'))).to be true
      end

      it 'accepts a card extending the high end' do
        expect(meld.accepts?(Rummy::Card.new('8', 'Hearts'))).to be true
      end

      it 'rejects a non-adjacent rank' do
        expect(meld.accepts?(Rummy::Card.new('9', 'Hearts'))).to be false
      end

      it 'rejects a different suit' do
        expect(meld.accepts?(Rummy::Card.new('8', 'Spades'))).to be false
      end
    end
  end

  describe '#accepts_sequence?' do
    let(:meld) do
      described_class.new(cards: [ Rummy::Card.new('5', 'Hearts'), Rummy::Card.new('6', 'Hearts'), Rummy::Card.new('7', 'Hearts') ])
    end

    it 'accepts a batch that applies cleanly in ascending order' do
      cards = [ Rummy::Card.new('8', 'Hearts'), Rummy::Card.new('9', 'Hearts') ]
      expect(meld.accepts_sequence?(cards)).to be true
    end

    it 'accepts a batch given in descending order by extending the low end' do
      cards = [ Rummy::Card.new('3', 'Hearts'), Rummy::Card.new('4', 'Hearts') ]
      expect(meld.accepts_sequence?(cards)).to be true
    end

    it 'rejects a batch with a gap that no ordering can bridge' do
      cards = [ Rummy::Card.new('9', 'Hearts'), Rummy::Card.new('10', 'Hearts') ]
      expect(meld.accepts_sequence?(cards)).to be false
    end

    it 'rejects a batch where no ordering bridges a gap left at either end' do
      cards = [ Rummy::Card.new('4', 'Hearts'), Rummy::Card.new('9', 'Hearts') ]
      expect(meld.accepts_sequence?(cards)).to be false
    end

    it 'accepts a batch of any order for a group meld' do
      group_meld = described_class.new(cards: [ Rummy::Card.new('7', 'Spades'), Rummy::Card.new('7', 'Hearts'), Rummy::Card.new('7', 'Diamonds') ])
      expect(group_meld.accepts_sequence?([ Rummy::Card.new('7', 'Clubs') ])).to be true
    end
  end

  describe '#description' do
    it 'describes a group meld' do
      meld = described_class.new(cards: [ Rummy::Card.new('K', 'Spades'), Rummy::Card.new('K', 'Hearts'), Rummy::Card.new('K', 'Diamonds') ])
      expect(meld.description).to eq 'three Kings'
    end

    it 'describes a 4-card group meld' do
      meld = described_class.new(cards: [
        Rummy::Card.new('K', 'Spades'), Rummy::Card.new('K', 'Hearts'),
        Rummy::Card.new('K', 'Diamonds'), Rummy::Card.new('K', 'Clubs')
      ])
      expect(meld.description).to eq 'four Kings'
    end

    it 'describes a run meld in ascending order regardless of input order, with no leading article' do
      meld = described_class.new(cards: [ Rummy::Card.new('7', 'Hearts'), Rummy::Card.new('5', 'Hearts'), Rummy::Card.new('6', 'Hearts') ])
      expect(meld.description).to eq 'run of 5-6-7 of Hearts'
    end
  end

  describe '#full?' do
    it 'returns false for a 3-card group' do
      meld = described_class.new(cards: [ Rummy::Card.new('7', 'Spades'), Rummy::Card.new('7', 'Hearts'), Rummy::Card.new('7', 'Diamonds') ])
      expect(meld.full?).to be false
    end

    it 'returns true for a 4-card group' do
      meld = described_class.new(cards: [
        Rummy::Card.new('7', 'Spades'), Rummy::Card.new('7', 'Hearts'),
        Rummy::Card.new('7', 'Diamonds'), Rummy::Card.new('7', 'Clubs')
      ])
      expect(meld.full?).to be true
    end

    it 'returns false for a run shorter than the full 13-card suit' do
      meld = described_class.new(cards: [ Rummy::Card.new('5', 'Hearts'), Rummy::Card.new('6', 'Hearts'), Rummy::Card.new('7', 'Hearts') ])
      expect(meld.full?).to be false
    end

    it 'returns true for a run covering all 13 cards of a suit' do
      cards = Rummy::Card::RUN_ORDER.map { |rank| Rummy::Card.new(rank, 'Hearts') }
      meld = described_class.new(cards: cards)
      expect(meld.full?).to be true
    end
  end

  describe '#group?' do
    it 'returns true for a group meld' do
      meld = described_class.new(cards: [ Rummy::Card.new('7', 'Spades'), Rummy::Card.new('7', 'Hearts'), Rummy::Card.new('7', 'Diamonds') ])
      expect(meld.group?).to be true
    end

    it 'returns false for a run meld' do
      meld = described_class.new(cards: [ Rummy::Card.new('5', 'Hearts'), Rummy::Card.new('6', 'Hearts'), Rummy::Card.new('7', 'Hearts') ])
      expect(meld.group?).to be false
    end
  end

  describe '#as_json' do
    it 'returns the cards as a plain array' do
      meld = described_class.new(cards: [ Rummy::Card.new('K', 'Spades'), Rummy::Card.new('K', 'Hearts') ])
      expect(meld.as_json).to eq [ { "rank" => 'K', "suit" => 'Spades' }, { "rank" => 'K', "suit" => 'Hearts' } ]
    end
  end

  describe '.from_json' do
    it 'restores the meld from its serialized cards' do
      json = [ { "rank" => 'K', "suit" => 'Spades' }, { "rank" => 'K', "suit" => 'Hearts' } ]
      expect(described_class.from_json(json).cards).to eq [ Rummy::Card.new('K', 'Spades'), Rummy::Card.new('K', 'Hearts') ]
    end
  end
end
