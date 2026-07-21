require 'rails_helper'

RSpec.describe Turn, type: :model do
  describe 'validations' do
    let!(:game) { create :started_game }
    let!(:user) { game.players.first.user }
    let!(:user2) { game.players.last.user }
    before { game.start! }

    it 'returns true if game is present and it is the players turn' do
      result = described_class.new(game: game, user: user)
      expect(result).to be_valid
    end

    it 'returns false if game is nil' do
      result = described_class.new(game: nil, user: user)
      expect(result).to be_invalid
    end

    it 'returns false if user is nil' do
      result = described_class.new(game: game, user: nil)
      expect(result).to be_invalid
    end

    it 'returns false if user is not in that game' do
      user3 = create(:user, email_address: 's@s.com')
      result = described_class.new(game: game, user: user3)
      expect(result).to be_invalid
    end

    it 'returns false if it is not the players turn' do
      result = described_class.new(game: game, user: user2)
      expect(result).to be_invalid
    end
  end
end
