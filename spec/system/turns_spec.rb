require 'rails_helper'
RSpec.describe 'Turns', type: :system do
  context 'when a valid turn is played' do
    let!(:user) { create :user }
    let!(:user2) { create :user2 }
    let!(:game) { create :started_game }
    let!(:player1) { create(:player, user:, game:) }
    let!(:player2) { create(:player, user: user2, game:) }
    before do
      sign_in_as user
      visit game_path(game)
      click_on 'Ask'
    end
    it 'displays a turn result' do
      expect(page).to have_selector('.game-feed__results')
      expect(current_path).to eq game_path(game)
    end
  end
end
