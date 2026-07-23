require 'rails_helper'

RSpec.describe Rummy::Player, type: :model do
  describe '#add_cards' do
    let(:player) { described_class.new(name: 'player1', id: 1) }
    let(:card1) { Rummy::Card.new('A', 'Spades') }
    let(:card2) { Rummy::Card.new('K', 'Spades') }

    context 'when player has no cards' do
      it 'adds cards in order' do
        player.add_cards([ card1, card2 ])
        expect(player.hand).to eq [ card1, card2 ]
      end
    end

    context 'when player already has cards' do
      let(:card3) { Rummy::Card.new('2', 'Spades') }
      before { player.hand = [ card3 ] }

      it 'appends the new cards' do
        player.add_cards([ card1, card2 ])
        expect(player.hand).to eq [ card3, card1, card2 ]
      end
    end
  end

  describe '#as_json' do
    let!(:player) { described_class.new(name: 'player1', id: 1) }
    let(:expected_hash) do
      {
        "name" => 'player1',
        "id" => 1,
        "hand" => [ { "rank" => 'J', "suit" => 'Spades' } ],
        "has_melded" => true
      }
    end

    it 'returns expected hash' do
      player.hand = [ Rummy::Card.new('J') ]
      player.has_melded = true
      expect(player.as_json).to eq expected_hash
    end
  end

  describe '.from_json' do
    let!(:player) { described_class.new(name: 'player1', id: 1) }
    before do
      player.hand = [ Rummy::Card.new('J') ]
      player.has_melded = true
    end

    it 'restores the state of the player' do
      json = player.as_json
      expect(described_class.from_json(json)).to have_attributes(
        name: player.name,
        id: player.id,
        hand: player.hand,
        has_melded: true
      )
    end
  end

  describe '#has_melded' do
    let(:player) { described_class.new(name: 'player1', id: 1) }

    it 'defaults to false for a new player' do
      expect(player.has_melded).to be false
    end

    it 'can be set to true once a player has melded' do
      player.has_melded = true
      expect(player.has_melded).to be true
    end
  end

  describe '#hand_pip_total' do
    let(:player) { described_class.new(name: 'player1', id: 1) }

    it 'sums the pip value of every card in hand' do
      player.hand = [ Rummy::Card.new('A'), Rummy::Card.new('7'), Rummy::Card.new('K') ]
      expect(player.hand_pip_total).to eq 18
    end

    it 'returns 0 for an empty hand' do
      expect(player.hand_pip_total).to eq 0
    end
  end

  describe '#hand_size' do
    let(:player) { described_class.new(name: 'player1', id: 1) }

    it 'returns 0 for an empty hand' do
      expect(player.hand_size).to eq 0
    end

    it 'returns the current number of cards in hand' do
      player.hand = [ Rummy::Card.new('A'), Rummy::Card.new('2') ]
      expect(player.hand_size).to eq 2
    end
  end

  describe '#empty_hand?' do
    let(:player) { described_class.new(name: 'player1', id: 1) }

    it 'returns true when the hand has no cards' do
      expect(player.empty_hand?).to be true
    end

    it 'returns false when the hand has cards' do
      player.hand = [ Rummy::Card.new('A') ]
      expect(player.empty_hand?).to be false
    end
  end

  describe '#remove_cards' do
    let(:player) { described_class.new(name: 'player1', id: 1) }
    let(:card1) { Rummy::Card.new('7', 'Spades') }
    let(:card2) { Rummy::Card.new('7', 'Hearts') }
    let(:card3) { Rummy::Card.new('9', 'Clubs') }

    before { player.hand = [ card1, card2, card3 ] }

    it 'removes exactly the given cards, leaving the rest' do
      player.remove_cards([ card1, card2 ])
      expect(player.hand).to eq [ card3 ]
    end
  end
end
