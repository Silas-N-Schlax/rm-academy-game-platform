require 'rails_helper'

RSpec.describe Game, type: :model do
  describe 'validations' do
    it 'returns true if given valid input' do
      game = build :game
      expect(game).to be_valid
    end

    it 'returns false if name is not valid' do
      game = build :game, name: nil
      expect(game).to be_invalid
    end

    it 'returns false if name is too short' do
      game = build :game, name: 'g'
      expect(game).to be_invalid
    end

    it 'returns false if type is not a valid type' do
      game = build :game, game_type: 'Scythe'
      expect(game).to be_invalid
    end

    it 'returns false if game size is to small for that game type' do
      game = build :game, game_size: 1
      expect(game).to be_invalid
    end

    it 'returns false if game size is to large for that game type' do
      game = build :game, game_size: 7
      expect(game).to be_invalid
    end

    it 'returns false if game size is not valid' do
      game = build :game, game_size: nil
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
      game.players.create!(user_id: user.id, game_id: game.id)
      expect(game.joined?(user.id)).to be true
    end
    it 'returns false if player has not joined' do
      expect(game.joined?(user.id)).to be false
    end
  end

  describe '#open_spots?' do
    let(:game) { create :game }
    let(:user) { create :user }
    it 'returns true if game is not full' do
      game.players.create!(user_id: user.id, game_id: game.id)
      expect(game.open_spots?).to be true
    end
    it 'returns false if game is full' do
      6.times do
        game.players.create!(user_id: user.id, game_id: game.id)
      end
      expect(game.open_spots?).to be false
    end
  end

  describe '#status' do
    let!(:game) { create :game }
    let(:user) { create :user }
    before { game.players.create!(user_id: user.id, game_id: game.id) }
    it 'returns "waiting" if game is waiting on more players' do
      expected_message = 'waiting'
      expect(game.status).to eq expected_message
    end

    it 'returns "started" if game has started' do
      game.started_at = Time.new
      expected_message = 'started'
      expect(game.status).to eq expected_message
    end

    it 'returns "finished" if game has finished' do
      game.finished_at = Time.new
      expected_message = 'finished'
      expect(game.status).to eq expected_message
    end

    it 'returns not full message if param passed in' do
      expected_message = '1/2 players'
      expect(game.status(message: true)).to eq expected_message
    end

    it 'returns full message if param passed in' do
      5.times do
        game.players.create!(user_id: user.id, game_id: game.id)
      end
      expected_message = 'started'
      expect(game.status(message: true)).to eq expected_message
    end
  end

  describe '#can_join?' do
    let!(:game) { create :game }
    let(:user) { create :user }
    # before { game.players.create!(user_id: user.id, game_id: game.id) }
    it 'returns true if user has not joined and the game is not started' do
      expect(game.can_join?(user.id)).to be true
    end

    it 'returns false if user cannot join if they have joined' do
      game.players.create!(user_id: user.id, game_id: game.id)
      expect(game.can_join?(user.id)).to be false
    end

    it 'returns false if the game is started' do
      game.started_at = Time.now
      expect(game.can_join?(user.id)).to be false
    end
  end
end
