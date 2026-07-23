require 'rails_helper'

RSpec.describe RummyTurn, type: :model do
  describe 'validations' do
    let!(:game) { create :started_game, type: 'RummyGame' }
    let(:player1) { game.players.first }
    let(:player2) { game.players.last }
    let!(:user) { player1.user }
    let!(:user2) { player2.user }

    before do
      game.start!
      implementation = game.game_state
      implementation.deck.cards = [ Rummy::Card.new('9') ]
      implementation.discard.cards = [ Rummy::Card.new('K') ]
      implementation.players.first.hand = [ Rummy::Card.new('2', 'Diamonds') ]
      game.game_state = implementation
      game.save!
    end

    it 'returns true for a valid draw' do
      turn = build(:rummy_turn, action: 'draw', source: 'stock', game:, user:)
      expect(turn).to be_valid
    end

    it 'returns false when the action is missing' do
      turn = build(:rummy_turn, action: nil, game:, user:)
      expect(turn).to be_invalid
    end

    it 'returns false when the action is not recognized' do
      turn = build(:rummy_turn, action: 'shuffle', game:, user:)
      expect(turn).to be_invalid
    end

    it 'returns false for a draw with no source' do
      turn = build(:rummy_turn, action: 'draw', source: nil, game:, user:)
      expect(turn).to be_invalid
    end

    it 'returns false for a draw with an unrecognized source' do
      turn = build(:rummy_turn, action: 'draw', source: 'pocket', game:, user:)
      expect(turn).to be_invalid
    end

    it 'returns false when it is not the players turn' do
      turn = build(:rummy_turn, action: 'draw', source: 'stock', game:, user: user2)
      expect(turn).to be_invalid
    end

    it 'returns false for a meld with fewer than 3 cards' do
      turn = build(:rummy_turn, action: 'meld', card_ids: [ '7:Spades', '7:Hearts' ], game:, user:)
      expect(turn).to be_invalid
    end

    it 'returns false for a discard with more than 1 card' do
      turn = build(:rummy_turn, action: 'discard', card_ids: [ '2:Diamonds', '9:Spades' ], game:, user:)
      expect(turn).to be_invalid
    end

    it 'returns false for a layoff with no meld_index' do
      turn = build(:rummy_turn, action: 'layoff', card_ids: [ '2:Diamonds' ], meld_index: nil, game:, user:)
      expect(turn).to be_invalid
    end

    it 'returns false when a selected card is not in the hand' do
      turn = build(:rummy_turn, action: 'discard', card_ids: [ '9:Spades' ], game:, user:)
      expect(turn).to be_invalid
    end
  end

  describe '#save' do
    let!(:game) { create :started_game, type: 'RummyGame' }

    before do
      game.start!
      implementation = game.game_state
      implementation.deck.cards = [ Rummy::Card.new('9') ]
      implementation.players.first.hand = [ Rummy::Card.new('2', 'Diamonds') ]
      game.game_state = implementation
      game.save!
    end

    it 'returns true and plays the move when the turn is valid' do
      turn = game.turn_class.new(game:, user: game.users.first, action: 'draw', source: 'stock')
      expect(turn.save).to be true
      expect(Game.find(game.id).game_state.players.first.hand_size).to eq 2
    end

    it 'returns false and does not mutate the game when the turn is invalid' do
      turn = game.turn_class.new(game:, user: game.users.first, action: 'shuffle')
      expect(turn.save).to be false
      expect(Game.find(game.id).game_state.players.first.hand_size).to eq 1
    end
  end
end
