require 'rails_helper'

RSpec.describe GoFish::Player, type: :model do
  describe '#add_cards' do
    let(:player) { described_class.new(name: 'player1') }
    let(:card1) { GoFish::Card.new('A', 'Spades') }
    let(:card2) { GoFish::Card.new('K', 'Spades') }
    context 'when player has no cards' do
      it 'adds cards to bottom in correct orders' do
        example_hand = [ card1, card2 ]
        player.add_cards(example_hand)
        expect(player.hand).to eq example_hand
        expect(player.hand_size).to eq 2
      end
    end

    context 'when player has cards' do
      let(:card3) { GoFish::Card.new('2', 'Spades') }
      before do
        player.hand = [ card3 ]
      end
      it 'adds cards in correct order and does not create deck' do
        example_hand = [ card3, card1, card2 ]
        player.add_cards([ card1, card2 ])
        expect(player.hand).to eq example_hand
        expect(player.hand_size).to eq example_hand.size
        expect(player.books_size).to be_zero
      end
    end

    context 'when a 4th card of the same rank is added' do
      before do
        player.hand = [ card1, card1, card1, card2 ]
      end
      it 'creates a book with that rank' do
        expected_books_size = 1
        expected_hand_size = 1
        expect(player.add_cards([ card1 ])).to be_a GoFish::Book
        expect(player.books_size).to eq expected_books_size
        expect(player.hand_size).to eq expected_hand_size
      end
    end
  end

  describe '#hand_size' do
    let(:player) { described_class.new(name: 'player1') }
    it 'returns the current hand size' do
      expect(player.hand_size).to eq 0
    end

    it 'returns current hand size of hand with 1 card' do
      player.add_cards([ GoFish::Card.new('A', 'Spades') ])
      expect(player.hand_size).to eq 1
    end

    it 'returns current hand size of hand with 2 cards' do
      player.add_cards([ GoFish::Card.new('A', 'Spades'), GoFish::Card.new('10', 'Spades') ])
      expect(player.hand_size).to eq 2
    end
  end

  describe '#take_cards_of_rank' do
    let(:player) { described_class.new(name: 'player') }
    context 'when player does not have the correct card' do
      it 'returns nil' do
        expect(player.take_cards_of_rank('A')).to be_empty
      end
    end

    context 'when player has one of the correct card' do
      let(:card) { GoFish::Card.new('A') }
      before do
        player.hand = [card, GoFish::Card.new('K'), GoFish::Card.new('J')]
      end

      it 'returns array of card and remove card from hand' do
        expect(player.take_cards_of_rank('A')).to eq [ card ]
        expect(player.hand_size).to eq 2
      end
    end

    context 'when player has two of the correct card' do
      let(:card1) { GoFish::Card.new('K') }
      let(:card2) { GoFish::Card.new('K') }
      before do
        player.hand = [card1, GoFish::Card.new('A'), card2]
      end
      it 'returns array of cards and remove cards from hand' do
        expect(player.take_cards_of_rank('K')).to eq [ card1, card2 ]
        expect(player.hand_size).to eq 1
      end
    end
  end

  describe '#books_size' do
    let(:player) { described_class.new(name: 'player1') }
    it 'returns the current hand size' do
      expect(player.books_size).to eq 0
    end
    it 'returns current hand size of hand with 1 card' do
      player.books = ([ GoFish::Book.new('A') ])
      expect(player.books_size).to eq 1
    end
    it 'returns current hand size of hand with 2 cards' do
      player.books = ([ GoFish::Book.new('A'), GoFish::Book.new('K') ])
      expect(player.books_size).to eq 2
    end
  end

  describe '#empty_hand?' do
    let(:player) { described_class.new(name: 'player1') }
    it 'returns false if hand is full' do
      player.add_cards([ GoFish::Card.new('J') ])
      expect(player.empty_hand?).to be false
    end

    it 'returns true if hand is empty' do
      expect(player.empty_hand?).to be true
    end
  end

  describe '#as_json' do
    let!(:player) { described_class.new(name: 'player1', id: 1) }
    let(:expected_hash) do
      {
        "name" => player.name,
        "id" => player.id,
        "books" => [],
        "hand" => [
          {
            "rank" => 'J',
            "suit" => 'Spades'
          }
        ]
      }
    end
    it 'returns expected hash' do
      player.hand = [ GoFish::Card.new('J') ]
      expect(player.as_json).to eq expected_hash
    end
  end

  describe '.from_json' do
    let!(:player) { described_class.new(name: 'player1', id: 1) }
    before do
      player.hand = [ GoFish::Card.new('J') ]
    end
    it 'restores current state of the player' do
      json = player.as_json
      expect(GoFish::Player.from_json(json)).to have_attributes(
        name: player.name,
        id: player.id,
        hand: player.hand,
        books: player.books
      )
    end
  end
end
