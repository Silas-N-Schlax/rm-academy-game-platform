require 'rails_helper'

RSpec.describe Game, type: :model do
  describe 'validations' do
    it 'returns true if given valid input' do
      game = build :game
      expect(game).to be_valid
    end

    it 'returns false if name is not valid' do
      game = build :no_name_game
      expect(game).to be_invalid
    end

    it 'returns false if name is too short' do
      game = build :short_name_game
      expect(game).to be_invalid
    end

    it 'returns false if type is not a valid type' do
      game = build :invalid_game_type_game
      expect(game).to be_invalid
    end

    it 'returns false if game size is to small for that game type' do
      game = build :too_small_game
      expect(game).to be_invalid
    end

    it 'returns false if game size is to large for that game type' do
      game = build :too_large_game
      expect(game).to be_invalid
    end

    it 'returns false if game size is not valid' do
      game = build :no_game_size_game
      expect(game).to be_invalid
    end
  end

  describe '#valid_types' do
    let(:game) { described_class.new }
    it 'returns array of types' do
      expected_output = [
        'Go Fish'
      ]
      expect(game.valid_game_types).to eq expected_output
    end
  end

  describe '#game_size_by_type' do
    let(:game) { described_class.new }
    it 'returns the min and max values in a hash for that type' do
      expected_min = 2
      expected_max = 6
      game_type = 'Go Fish'
      result = game.game_size_by_game_type(game_type)
      expect(result[:min]).to eq expected_min
      expect(result[:max]).to eq expected_max
    end
  end


  describe '#joined?' do
    let(:game) { create :game }
    let(:user) { create :user }
    it 'returns true if player has already joined' do
      game.players.create(user_id: user.id, game_id: game.id)
      expect(game.joined?(user.id)).to be true
    end
    it 'returns false if player has not joined' do
      expect(game.joined?(user.id)).to be false
    end
  end

  describe '#open_spots?' do
    let(:game) { create(:game, player_count: 0) }
    let(:user) { create :user }
    it 'returns true if game is not full' do
      game.players.create(user_id: user.id, game_id: game.id)
      expect(game.open_spots?).to be true
    end
    it 'returns false if game is full' do
      6.times do |i|
        user = create :user, email_address: "example#{i}@example.com"
        game.players.create(user_id: user.id, game_id: game.id)
      end
      expect(game.open_spots?).to be false
    end
  end

  describe '#status' do
    let!(:game) { create(:game, player_count: 1) }
    let(:user) { create :user }
    it 'returns "waiting" if game is waiting on more players' do
      game = build :waiting_game
      expected_message = 'waiting'
      expect(game.status).to eq expected_message
    end

    it 'returns "started" if game has started' do
      game = build :started_game
      expected_message = 'started'
      expect(game.status).to eq expected_message
    end

    it 'returns "finished" if game has finished' do
      game = build :finished_game
      expected_message = 'finished'
      expect(game.status).to eq expected_message
    end

    it 'returns not full message if param passed in' do
      expected_message = '1/2 players'
      expect(game.status(message: true)).to eq expected_message
    end

    it 'returns full message if param passed in' do
      5.times do |i|
        user = create :user, email_address: "example#{i}@example.com"
        game.players.create(user_id: user.id, game_id: game.id)
      end
      expected_message = 'started'
      expect(game.status(message: true)).to eq expected_message
    end
  end

  describe '#can_join?' do
    let!(:game) { create(:game, player_count: 1) }
    let(:user) { create :user }
    it 'returns true if user has not joined and the game is not started' do
      expect(game.can_join?(user.id)).to be true
    end

    it 'returns false if user cannot join if they have joined' do
      game.players.create(user_id: user.id, game_id: game.id)
      expect(game.can_join?(user.id)).to be false
    end

    it 'returns false if the game is started' do
      game = build :started_game
      expect(game.can_join?(user.id)).to be false
    end
  end

  describe '#formatted_time' do
    it 'returns formatted time' do
      game = build :finished_game
      expected_output = '8760:00:00'
      expect(game.formatted_time).to eq expected_output
    end
    it 'returns zero if game is not finished' do
      game = build :started_game
      expect(game.formatted_time).to be_zero
    end
  end

  describe '#winner' do
    let!(:user) { create :user }
    let!(:game) { create :finished_game }
    let!(:player) { create(:player_as_winner, user:, game:) }
    it 'returns the winner' do
      expect(game.winner).to eq player
    end
  end

  describe '#open-games' do
    let!(:game1) { create(:game, player_count: 0) }
    let!(:game2) { create :finished_game }
    let!(:game3) { create(:game, player_count: 1) }
    it 'returns list of open games' do
      expected_output = [ game1 ]
      game = described_class.new
      expect(game.open_games).to eq expected_output
    end
  end

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
end
