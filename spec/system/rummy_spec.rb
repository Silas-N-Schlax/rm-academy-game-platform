require 'rails_helper'
RSpec.describe 'Rummy', type: :system do
  let!(:user) { create(:user) }

  context 'when a user creates a new Rummy game' do
    it 'creates the game and sends the user to that page' do
      game_name = 'Rummy Night'
      sign_in_as user
      visit new_game_path
      expect do
        fill_in 'Name', with: game_name
        select 'Rummy Game', from: 'Type'
        fill_in 'Game size', with: 2
        click_on 'Create Game'
        expect(page).to have_content game_name
      end.to change(Game, :count).by 1
      expect(RummyGame.last).to be_a RummyGame
    end
  end

  context 'when a Rummy game has been dealt' do
    let!(:game) { create :game, type: 'RummyGame' }
    before do
      game.start!
      sign_in_as game.users.first
      visit game_path(game.reload)
    end

    it 'renders the dealt hand, stock, discard, and opponent' do
      implementation = game.game_state
      your_player = implementation.find_player(game.users.first.id)
      opponent = implementation.find_player(game.users.last.id)
      expect(page).to have_content "Stock: #{implementation.deck.cards_left}"
      expect(page).to have_selector('.game-board__hand .playing-card', count: your_player.hand.size)
      expect(page).to have_content opponent.name
      expect(page).to have_content opponent.hand.size
    end
  end
end
