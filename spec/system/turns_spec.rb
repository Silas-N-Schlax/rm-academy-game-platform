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
    end
    it 'displays a turn result' do
      visit game_path(game)
      click_on 'Ask'
      expect(current_path).to eq game_path(game)
      expect(page).to have_selector('.game-feed__results')
    end

    context 'when the game is over' do
      before do
        game.start!
        game_state = game.game_state
        game_state.deck.cards = []
        game_state.players.first.hand = [ GoFish::Card.new('A'), GoFish::Card.new('A'), GoFish::Card.new('A') ]
        game_state.players.last.hand = [ GoFish::Card.new('A') ]
        game.save!
      end
      it 'display a game over view' do
        expected_content = 'Game Over'
        visit game_path(game)
        click_on 'Ask'
        expect(page).to have_content expected_content
        expect(page).to have_content player1.user.name
      end
    end
  end
end
