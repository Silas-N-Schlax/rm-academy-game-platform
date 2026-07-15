require 'rails_helper'

RSpec.describe CrazyEights::Player, type: :model do
  describe '#add_cards' do
    let(:player) { described_class.new(name: 'player1') }
    let(:card1) { CrazyEights::Card.new('A', 'Spades') }
    let(:card2) { CrazyEights::Card.new('K', 'Spades') }
    context 'when player has no cards' do
      it 'adds cards to bottom in correct orders' do
        example_hand = [ card1, card2 ]
        player.add_cards(example_hand)
        expect(player.hand).to eq example_hand
        expect(player.hand_size).to eq 2
      end
    end

    context 'when player has cards' do
      let(:card3) { CrazyEights::Card.new('2', 'Spades') }
      before do
        player.hand = [ card3 ]
      end
      it 'adds cards in correct order' do
        example_hand = [ card3, card1, card2 ]
        player.add_cards([ card1, card2 ])
        expect(player.hand).to eq example_hand
        expect(player.hand_size).to eq example_hand.size
      end
    end
  end

  describe '#hand_size' do
    let(:player) { described_class.new(name: 'player1') }
    it 'returns the current hand size' do
      expect(player.hand_size).to eq 0
    end

    it 'returns current hand size of hand with 1 card' do
      player.add_cards([ CrazyEights::Card.new('A', 'Spades') ])
      expect(player.hand_size).to eq 1
    end

    it 'returns current hand size of hand with 2 cards' do
      player.add_cards([ CrazyEights::Card.new('A', 'Spades'), CrazyEights::Card.new('10', 'Spades') ])
      expect(player.hand_size).to eq 2
    end
  end

  describe '#take_card' do
    let(:player) { described_class.new(name: 'player') }
    context 'when player does not have the correct card' do
      it 'returns nil' do
        expect(player.take_card('A', 'Spades')).to be_nil
      end
    end

    context 'when player has one of the correct card' do
      let(:card) { CrazyEights::Card.new('A') }
      before do
        player.hand = [ card, CrazyEights::Card.new('K'), CrazyEights::Card.new('J') ]
      end

      it 'returns the card and remove card from hand' do
        expected_hand_size = 2
        expect(player.take_card('A', 'Spades')).to eq card
        expect(player.hand_size).to eq expected_hand_size
      end
    end

    context 'when the card taken is a wild' do
      let(:card) { CrazyEights::Card.new('8', 'Spades') }
      before do
        player.hand = [ card, CrazyEights::Card.new('K'), CrazyEights::Card.new('J') ]
      end

      it 'returns the card with a wild suit and remove card from hand' do
        expected_hand_size = 2
        expect(player.take_card('8', 'Spades')).to eq card
        expect(player.hand_size).to eq expected_hand_size
      end
    end

    context 'when player has two cards of the same rank' do
      let(:card1) { CrazyEights::Card.new('K') }
      let(:card2) { CrazyEights::Card.new('K', 'Hearts') }
      before do
        player.hand = [ card1, card2 ]
      end
      it 'removes card of correct rank and suit' do
        expected_hand_size = 1
        expect(player.take_card('K', 'Spades')).to eq card1
        expect(player.hand_size).to eq expected_hand_size
      end
    end
  end

  describe '#empty_hand?' do
    let(:player) { described_class.new(name: 'player1') }
    it 'returns false if hand is full' do
      player.add_cards([ CrazyEights::Card.new('J') ])
      expect(player.empty_hand?).to be false
    end

    it 'returns true if hand is empty' do
      expect(player.empty_hand?).to be true
    end
  end

  describe '#sorted_hand' do
    let(:player) { described_class.new(name: 'player1') }
    let(:card) { CrazyEights::Card.new('10') }
    let(:card1) { CrazyEights::Card.new('2') }
    let(:card2) { CrazyEights::Card.new('3', 'Hearts') }
    before do
      player.hand = [ card, card1, card2 ]
    end
    it 'returns sorted array by rank' do
      sorted_array = [ card1, card, card2 ]
      expect(player.sorted_hand).to eq sorted_array
    end
  end

  describe '#has_card?' do
    let(:player) { described_class.new(name: 'player1') }
    let(:card) { CrazyEights::Card.new('10') }
    before do
      player.hand = [ card ]
    end
    it 'returns true if the player has that card' do
      expect(player.has_card?(card.rank, card.suit)).to eq true
    end
    it 'returns valse if hte player does not have that card' do
      expect(player.has_card?(card.rank, 'obi')).to eq false
    end
  end

  describe '#can_play?' do
    let(:player) { described_class.new(name: 'player1') }
    let(:card) { CrazyEights::Card.new('J') }
    it 'returns true when the player has a card they can play' do
      player.hand = [ CrazyEights::Card.new('2'), CrazyEights::Card.new('J') ]
      expect(player.can_play?(card.rank, card.suit)).to be true
    end

    it 'returns true if the player has 8 (wild)' do
      player.hand = [ CrazyEights::Card.new('8', 'Hearts') ]
      expect(player.can_play?(card.rank, card.suit)).to be true
    end

    it 'returns false when the player does not a card they can play' do
      player.hand = [ CrazyEights::Card.new('2', 'Hearts') ]
      expect(player.can_play?(card.rank, card.suit)).to be false
    end
  end

  describe '#as_json' do
    let!(:player) { described_class.new(name: 'player1', id: 1) }
    let(:expected_hash) do
      {
        "name" => player.name,
        "id" => player.id,
        "hand" => [
          {
            "rank" => 'J',
            "suit" => 'Spades'
          }
        ]
      }
    end
    it 'returns expected hash' do
      player.hand = [ CrazyEights::Card.new('J') ]
      expect(player.as_json).to eq expected_hash
    end
  end

  describe '.from_json' do
    let!(:player) { described_class.new(name: 'player1', id: 1) }
    before do
      player.hand = [ CrazyEights::Card.new('J') ]
    end
    it 'restores current state of the player' do
      json = player.as_json
      expect(CrazyEights::Player.from_json(json)).to have_attributes(
        name: player.name,
        id: player.id,
        hand: player.hand,
      )
    end
  end
end
