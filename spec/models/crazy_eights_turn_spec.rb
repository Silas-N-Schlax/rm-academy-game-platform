require 'rails_helper'

RSpec.describe CrazyEightsTurn, type: :model do
  describe 'validations' do
    let!(:game) { create :started_game, type: 'CrazyEightsGame' }
    let(:player1) { game.players.first }
    let(:player2) { game.players.last }
    let!(:user) { player1.user }
    let!(:user2) { player2.user }
    before do
      game.start!
      implementation = game.game_state
      implementation.players.first.hand = [ CrazyEights::Card.new('A') ]
      implementation.deck.cards = [ CrazyEights::Card.new('10') ]
      implementation.discard.cards = [ CrazyEights::Card.new('4') ]
      game.game_state = implementation
      game.save!
    end
    it 'returns true if all input is valid to play a card' do
      result = build(:crazy_eights_turn, suit: 'Spades', game: game, user: user)
      expect(result).to be_valid
    end

    it 'returns true if all the input is valid to play a wild' do
      result = build(:crazy_eights_turn, suit: 'Spades', wild_suit: 'Hearts', game: game, user: user)
      expect(result).to be_valid
    end

    it 'returns true if request is present' do
      result = build(:crazy_eights_turn, rank: nil, suit: nil, request: true, game:, user:)
      expect(result).to be_valid
    end

    it 'returns false if game is nil' do
      result = build(:crazy_eights_turn, rank: nil, game: nil, user: user)
      expect(result).to be_invalid
    end

    it 'returns false if user is nil' do
      result = build(:crazy_eights_turn, game: game, user: nil)
      expect(result).to be_invalid
    end

    it 'returns false if rank is nil' do
      result = build(:crazy_eights_turn, rank: nil, game: game, user: user)
      expect(result).to be_invalid
    end

    it 'returns false if user is not in that game' do
      user3 = create(:user, email_address: 's@s.com')
      result = build(:crazy_eights_turn, game: game, user: user3)
      expect(result).to be_invalid
    end

    it 'returns false if rank is not a valid' do
      result = build(:crazy_eights_turn, rank: 'J', game: game, user: user)
      expect(result).to be_invalid
    end

    it 'returns false if suit is nil' do
      result = build(:crazy_eights_turn, suit: nil, game: game, user: user)
      expect(result).to be_invalid
    end
    it 'returns false if suit is not valid' do
      result = build(:crazy_eights_turn, suit: 'Hearts', game: game, user: user)
      expect(result).to be_invalid
    end

    it 'returns false when it is not the players turn' do
      result = build(:crazy_eights_turn, game: game, user: user2)
      expect(result).to be_invalid
    end

    it 'returns false when a request is submitted and it is not the players turn' do
      result = build(:crazy_eights_turn, rank: nil, suit: nil, request: true, game: game, user: user2)
      expect(result).to be_invalid
    end

    it 'returns false when the card is an eight and there is no wild suit' do
      result = build(:crazy_eights_turn, rank: '8', game: game, user: user)
      expect(result).to be_invalid
    end
  end


  describe '#save' do
    let(:game) { create(:game, type: 'CrazyEightsGame') }
    before do
      game.start!
      implementation = game.game_state
      implementation.discard = [ CrazyEights::Card.new('J') ]
      implementation.players.first.hand = [ CrazyEights::Card.new('J', 'Hearts') ]
      game.save
    end
    it 'returns true if turn was valid from a played card' do
      turn = game.turn_class.new(game: game, user: game.users.first, rank: 'J', suit: 'Hearts')
      expect(turn.save).to be true
    end

    it 'returns true if turn was valid from a request' do
      turn = game.turn_class.new(game: game, user: game.users.first, request: true)
      expect(turn.save).to be true
    end

    it 'returns false if turn was invalid ' do
      turn = game.turn_class.new(game: game, user: game.users.first, rank: 'J', suit: 'Spades')
      expect(turn.save).to be false
    end
  end
end
