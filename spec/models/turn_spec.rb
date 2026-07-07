require 'rails_helper'

RSpec.describe Turn, type: :model do
  describe 'validations' do
    let!(:user) { create :user }
    let!(:user2) { create :user2 }
    let!(:game) { create :started_game }
    let!(:player1) { create(:player, user:, game:) }
    let!(:player2) { create(:player, user: user2, game:) }
    it 'returns true if all input is valid' do
      result = build(:turn, player: player2.id, game_id: game.id, user_id: user.id)
      game.start!
      game.game_state.players.first.hand = [ GoFish::Card.new('A') ]
      game.game_state = game.game_state
      game.save!
      expect(result).to be_valid
    end

    it 'returns false if rank is nil' do
      result = build(:turn, rank: nil, player: player2.id, game_id: game.id, user_id: user.id)
      game.start!
      expect(result).to be_invalid
    end

    it 'returns false if invalid game_id' do
      result = build(:turn, rank: nil, player: player2.id, game_id: 0, user_id: user.id)
      game.start!
      expect(result).to be_invalid
    end

    it 'returns false if user is not in that game' do
      user3 = create(:user, email_address: 's@s.com')
      result = build(:turn, rank: nil, player: player2.id, game_id: game.id, user_id: user3.id)
      game.start!
      expect(result).to be_invalid
    end

    it 'returns false if rank is not a valid' do
      result = build(:turn, rank: 'J', player: player2.id, game_id: game.id, user_id: user.id)
      game.start!
      game.game_state.players.first.hand = [ GoFish::Card.new('A') ]
      game.game_state = GoFish::Game.dump(game.game_state)
      game.save!
      game.start!
      expect(result).to be_invalid
    end

    it 'returns false if player is nil' do
      result = build(:turn, game_id: game.id, user_id: user.id)
      game.start!
      expect(result).to be_invalid
    end
    it 'returns false if player is not valid' do
      result = build(:turn, player: 0, game_id: game.id, user_id: user.id)
      game.start!
      expect(result).to be_invalid
    end
  end

  describe '#play' do
    context 'when a valid turn is played' do
      let!(:user) { create :user }
      let!(:user2) { create :user2 }
      let!(:game) { create :started_game }
      let!(:player1) { create(:player, user:, game:) }
      let!(:player2) { create(:player, user: user2, game:) }
      before { game.start! }
      it 'saves updated game to the database' do
        before_timestamp = game.updated_at
        turn = build(:turn, player: user2.id, game_id: game.id, user_id: user.id)
        turn.play
        updated_game = Game.find_by(id: game.id)
        original_player = game.game_state.players.first
        player = updated_game.game_state.players.first
        expect(updated_game.updated_at).to_not eq before_timestamp
        expect(player.hand_size).to be >= original_player.hand_size + 1
      end
    end
  end
end
