require 'rails_helper'

RSpec.describe RummyGame, type: :model do
  describe '#engine_class' do
    it 'returns the Rummy engine' do
      expect(described_class.new.engine_class).to eq Rummy::Game
    end
  end

  describe '#start!' do
    let!(:game) { create :game, type: 'RummyGame' }

    context 'when the game has the right amount of players' do
      it 'starts a game and returns the object' do
        expected_stock_size = 52 - (2 * 10) - 1
        result = game.start!
        expect(result).to be_a Rummy::Game
        expect(result.deck.cards_left).to eq expected_stock_size
        expect(Game.find_by(id: game.id).started_at).to_not be_nil
      end
    end

    context 'when the game does not have enough players' do
      it 'returns nil' do
        user3 = create(:user, email_address: 's@s.com')
        create(:player, user: user3, game:)
        expect(game.start!).to be_nil
      end
    end

    context 'when the game has already been started' do
      it 'returns the game object without re-dealing' do
        game.start!
        result = game.start!
        expected_stock_size = 52 - (2 * 10) - 1
        expect(result.deck.cards_left).to eq expected_stock_size
        expect(result).to be_a Rummy::Game
      end
    end
  end

  describe '#play' do
    let!(:game) { create :started_game, type: 'RummyGame' }
    let(:db_game) { Game.find_by(id: game.id) }

    context 'drawing from the stock' do
      before do
        game.start!
        implementation = game.game_state
        implementation.deck.cards = [ Rummy::Card.new('9') ]
        implementation.players.first.hand = [ Rummy::Card.new('2', 'Diamonds') ]
        game.save!
      end

      it 'saves the updated game to the database' do
        before_timestamp = db_game.updated_at
        db_game.play(action: 'draw', source: 'stock')
        updated_game = Game.find_by(id: game.id)
        expect(updated_game.updated_at).to_not eq before_timestamp
        expect(updated_game.game_state.players.first.hand_size).to eq 2
      end
    end

    context 'when the move goes out' do
      before do
        game.start!
        implementation = game.game_state
        implementation.deck.cards = []
        implementation.discard.cards = [ Rummy::Card.new('2') ]
        implementation.players.first.hand = [
          Rummy::Card.new('7', 'Spades'), Rummy::Card.new('7', 'Hearts'), Rummy::Card.new('7', 'Diamonds')
        ]
        game.save!
      end

      it 'saves the finished_at timestamp and the winner' do
        db_game.play(action: 'meld', card_ids: [ '7:Spades', '7:Hearts', '7:Diamonds' ])
        updated_game = Game.find_by(id: game.id)
        expect(updated_game.finished_at).to_not be_nil
        expect(updated_game.players.first.winner).to be true
      end
    end
  end

  describe '#valid_move?' do
    let!(:game) { create :started_game, type: 'RummyGame' }

    before do
      game.start!
      implementation = game.game_state
      implementation.deck.cards = []
      implementation.discard.cards = [ Rummy::Card.new('K') ]
      game.save!
    end

    it 'returns true for a legal draw' do
      expect(game.valid_move?(action: 'draw', source: 'discard')).to be true
    end

    it 'returns false for an illegal stock draw when the stock is empty and discard has only 1 card' do
      expect(game.valid_move?(action: 'draw', source: 'stock')).to be false
    end
  end

  describe '#turn_class' do
    let!(:game) { create :started_game, type: 'RummyGame' }

    it 'returns the RummyTurn class' do
      expect(game.turn_class).to eq RummyTurn
    end
  end
end
