require 'rails_helper'

RSpec.describe GoFishTurn, type: :model do
  describe 'validations' do
    let!(:game) { create :started_game }
    let(:player1) { game.players.first }
    let(:player2) { game.players.last }
    let!(:user) { player1.user }
    let!(:user2) { player2.user }
    before do
      game.start!
      game.game_state.players.first.hand = [ GoFish::Card.new('A') ]
      game.game_state = game.game_state
      game.save!
    end
    it 'returns true if all input is valid' do
      result = build(:go_fish_turn, player: user2.id, game: game, user: user)
      expect(result).to be_valid
    end

    it 'returns false if rank is nil' do
      result = build(:go_fish_turn, rank: nil, player: user2.id, game: game, user: user)
      expect(result).to be_invalid
    end

    it 'returns false if user is not in that game' do
      user3 = create(:user, email_address: 's@s.com')
      result = build(:go_fish_turn, player: user2.id, game: game, user: user3)
      expect(result).to be_invalid
    end

    it 'returns false if rank is not a valid' do
      result = build(:go_fish_turn, rank: 'J', player: user2.id, game: game, user: user)
      expect(result).to be_invalid
    end

    it 'returns false if player is nil' do
      result = build(:go_fish_turn, game: game, user: user)
      expect(result).to be_invalid
    end
    it 'returns false if player is not valid' do
      result = build(:go_fish_turn, player: 0, game: game, user: user)
      expect(result).to be_invalid
    end

    context 'when it is not the players turn' do
      it 'returns false' do
        result = build(:go_fish_turn, player: user.id, game: game, user: user2)
        expect(result).to be_invalid
      end
    end

    context 'when a non-current player spoofs an otherwise-valid move' do
      let!(:game) { create :started_game, game_size: 3, player_count: 3 }
      let(:player3) { game.players.third }
      let!(:user3) { player3.user }
      before do
        game.start!
        game.game_state.players.first.hand = [ GoFish::Card.new('A') ]
        game.game_state = game.game_state
        game.save!
      end

      it 'returns false even though the target and rank are valid for the current player' do
        result = build(:go_fish_turn, player: user3.id, rank: 'A', game: game, user: user2)
        expect(result).to be_invalid
      end
    end
  end

  describe '#save' do
    it 'returns true if turn was valid' do
      game = create :game
      game.start!
      game.game_state.players.first.hand = [ GoFish::Card.new('J') ]
      game.save!
      turn = game.turn_class.new(game: game, user: game.users.first, rank: 'J', player: game.users.last.id)
      expect(turn.save).to be true
    end
  end

  describe '#players' do
    let!(:game) { create(:game, game_size: 4, player_count: 4) }
    before { game.start! }
    it 'returns a list of players in the game that is not the current user' do
      turn = build(:go_fish_turn, game: game, user: game.users.first)
      expect(turn.players.size).to eq game.game_state.players.size - 1
    end
  end

  describe '#ranks' do
    let!(:game) { create(:game, game_size: 4, player_count: 4) }
    before { game.start! }
    it 'returns a list of ranks in the players hand' do
      turn = build(:go_fish_turn, game: game, user: game.users.first)
      implementation = game.game_state
      expect(turn.ranks).to eq implementation.find_player(game.users.first.id).ranks
    end
  end
end
