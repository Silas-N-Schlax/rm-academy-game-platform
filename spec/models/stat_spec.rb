require 'rails_helper'
RSpec.describe Stat, type: :model do
  let!(:user1) { create :user }
  let!(:user2) { create :user }
  let!(:game1) { create(:finished_game) }
  let!(:game2) { create(:finished_game) }
  let!(:game3) { create(:finished_game) }
  let!(:game4) { create(:finished_game) }
  let!(:game5) { create(:finished_game) }
  let(:stat) { described_class.new }
  before do
    [ game1, game2, game3 ].each do |game|
      create(:player_as_winner, user: user1, game:)
      create(:player, user: user2, game:)
    end
    create(:player, user: user1, game: game4)
    create(:player_as_winner, user: user2, game: game4)
  end
  describe '#total_games' do
    it 'returns the correct number' do
      expected_output = 4
      expect(stat.total_games(user1)).to eq expected_output
    end
  end

  describe '#total_wins' do
     it 'returns the correct number' do
      expected_output = 3
      expect(stat.total_wins(user1)).to eq expected_output
    end
  end

  describe '#total_losses' do
     it 'returns the correct number' do
      expected_output = 1
      expect(stat.total_losses(user1)).to eq expected_output
    end
  end

  describe '#total_average' do
     it 'returns the correct number' do
      expected_output = 75
      expect(stat.total_average(user1)).to eq expected_output
    end
  end

    describe '#total_games_by_game' do
    it 'returns the correct number' do
      expected_output = 4
      expect(stat.total_games_by_game(user1)).to eq expected_output
    end
  end

  describe '#total_wins_by_game' do
     it 'returns the correct number' do
      expected_output = 3
      expect(stat.total_wins_by_game(user1)).to eq expected_output
    end
  end

  describe '#total_losses_by_game' do
     it 'returns the correct number' do
      expected_output = 1
      expect(stat.total_losses_by_game(user1)).to eq expected_output
    end
  end

  describe '#total_average_by_game' do
     it 'returns the correct number' do
      expected_output = 75
      expect(stat.total_average_by_game(user1)).to eq expected_output
    end
  end
end
