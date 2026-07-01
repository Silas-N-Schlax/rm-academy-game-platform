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
end
