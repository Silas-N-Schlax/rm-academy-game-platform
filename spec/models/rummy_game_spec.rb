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
end
