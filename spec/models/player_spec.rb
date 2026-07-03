require 'rails_helper'

RSpec.describe Player, type: :model do
  describe 'validations' do
    let(:game) { build :game }
    let(:user) { build :user }
    let(:expected_message) { "Game You cannot join this game" }
    it 'does not allow user to join twice' do
      valid_player = build(:player, game:, user:)
      expect(valid_player).to be_valid
      valid_player.save
      invalid_player = build(:player, game:, user:)
      expect(invalid_player).to be_invalid
      expect(invalid_player.errors.full_messages.to_sentence).to eq expected_message
    end
  end
end
