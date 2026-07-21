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

  describe '#valid_type' do
    it 'returns array' do
      game = Game.new(name: 'test', type: 'GoFishGame', game_size: 2)
      game.save_new_game(create(:user).id)
      expected_array = [ "GoFishGame", "CrazyEightsGame" ]
      expect(game.valid_types).to eq expected_array
    end
  end

  describe '#save_new_game' do
    it 'saves game with one player to the database' do
      game = Game.new(name: 'test', type: 'GoFishGame', game_size: 2)
      game.save_new_game(create(:user).id)
      expected_game_size = 1
      expect(game.persisted?).to be true
      expect(game.players.size).to eq expected_game_size
    end
  end
  describe '#game_size_by_type' do
    let(:game) { described_class.new }
    it 'returns the min and max values in a hash for that type' do
      expected_min = 2
      expected_max = 6
      type = 'GoFishGame'
      result = game.game_size_by_type(type)
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

    it 'returns amount of players message if param passed in' do
      expected_message = '1/2 players'
      expect(game.status(message: true)).to eq expected_message
    end

    it 'returns started message if params passed in' do
      expected_message = 'started'
      game.started_at = Time.current
      expect(game.status(message: true)).to eq expected_message
    end

    it 'returns full message if param passed in' do
      game = create(:game, game_size: 6, player_count: 6)
      expected_message = '6/6 players'
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

  describe '#players_turn?' do
    let!(:game) { create :started_game }
    before { game.start! }

    it 'returns true for the current player' do
      expect(game.players_turn?(game.users.first.id)).to be true
    end

    it 'returns false for a player who is not current' do
      expect(game.players_turn?(game.users.last.id)).to be false
    end
  end

  describe '#open_games' do
    let!(:game1) { create(:game, player_count: 1) }
    let!(:game2) { create :finished_game }
    let!(:game3) { create(:game, player_count: 1) }
    let!(:game4) { create(:archived_game, player_count: 1) }
    it 'returns list of open games', :js do
      expected_output = [ game1.id, game3.id ].sort
      game = described_class.new
      expect(game.open_games(game3.users.first).map(&:id).sort).to eq expected_output
    end
  end
end
