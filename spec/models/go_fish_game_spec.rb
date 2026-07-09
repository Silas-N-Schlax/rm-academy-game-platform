require 'rails_helper'

RSpec.describe GoFishGame, type: :model do
  describe '#start!' do
    let!(:game) { create :game }
    context 'when a game has not already been started' do
      context 'when the game has the right amount of players' do
        it 'starts a game and returns the object' do
          expected_remaining_cards = 38
          result = game.start!
          expect(result.deck.cards_left).to eq expected_remaining_cards
          expect(result).to be_a GoFish::Game
          expect(Game.find_by(id: game.id).started_at).to_not be_nil
          expect(Game.find_by(id: game.id).updated_at).to_not be_nil
        end
      end

      context 'when the games does not have enough players' do
        it 'returns nil' do
          user3 = create(:user, email_address: 's@s.com')
          create(:player, user: user3, game:)
          expect(game.start!).to be_nil
        end
      end
    end

    context 'when a game has already been started' do
      it 'returns game object' do
        game.start!
        result = game.start!
        expected_remaining_cards = 38
        expect(result.deck.cards_left).to eq expected_remaining_cards
        expect(result).to be_a GoFish::Game
      end
    end
  end

  describe '#play' do
    let!(:game) { create :started_game }
    let(:user) { game.players.first.user }
    let(:user2) { game.players.last.user }
    context 'when a valid turn is played' do
      let(:db_game) { Game.find_by(id: game.id) }
      before { game.start! }
      it 'saves updated game to the database' do
        before_timestamp = db_game.updated_at
        db_game.play(user2.id, 'A', user.id)
        updated_game = Game.find_by(id: game.id)
        original_player = db_game.game_state.players.first
        player = updated_game.game_state.players.first
        expect(updated_game.updated_at).to_not eq before_timestamp
        expect(player.hand_size).to be >= original_player.hand_size
      end
    end

    context 'when the game is over' do
      let(:db_game) { Game.find_by(id: game.id) }
      before do
        game.start!
        game_state = game.game_state
        game_state.deck.cards = []
        game_state.players.first.hand = [ GoFish::Card.new('A'), GoFish::Card.new('A'), GoFish::Card.new('A') ]
        game_state.players.last.hand = [ GoFish::Card.new('A') ]
        game.save!
      end
      it 'saves the finished at timestamp' do
        db_game.play(user2.id, 'A', user.id)
        updated_game = Game.find_by(id: game.id)
        expect(updated_game.finished_at).to_not be_nil
        expect(updated_game.players.first.winner).to be true
      end
    end
  end

  describe '#valid_move?' do
    let!(:game) { create :started_game }
    let(:player1) { game.game_state.players.first }
    let(:player2) { game.game_state.players.last }
    before do
      game.start!
      players = game.game_state.players
      players.first.hand = [ GoFish::Card.new('J') ]
    end
    it 'returns true if player and rank is true' do
      expect(game.valid_move?(player2.id, 'J')).to be true
    end

    it 'returns false if rank is invalid' do
      expect(game.valid_move?(player2.id, 'K')).to be false
    end

    it 'returns false if player is invalid' do
      expect(game.valid_move?(player1.id, 'J')).to be false
    end
  end

  describe '#turn_class' do
    let!(:game) { create :started_game }
    it 'sends valid a GoFish turn class' do
      expect(game.turn_class).to be_a GoFishTurn.class
    end
  end

  describe '#players' do
    let!(:game) { create(:game, game_size: 4, player_count: 4) }
    before { game.start! }
    it 'returns a list of players in the game that is not the current user' do
      game_players = game.game_state.players
      expect(game.players_list(game_players.first.id).size).to eq game.game_state.players.size - 1
    end
  end

  describe '#ranks' do
    let!(:game) { create(:game, game_size: 4, player_count: 4) }
    before { game.start! }
    it 'returns a list of ranks in the players hand' do
      game_players = game.game_state.players
      expect(game.ranks_list(game_players.first.id)).to eq game_players.first.ranks
    end
  end
end
