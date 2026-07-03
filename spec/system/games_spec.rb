require 'rails_helper'
RSpec.describe 'Games', type: :system do
  let!(:user) { create(:user) }

  context 'when the user goes to the index' do
    let!(:game) { create :game }
    let!(:game2) { create :game }
    before do
      sign_in_as user
      visit games_path
      game.players.create(user_id: user.id, game_id: game.id)
    end
    it 'shows the games index' do
      expect(page).to have_content 'Your Games'
      expect(page).to have_content 'Open Games'
    end

    it 'shows open games and users games' do
      visit root_path
      expect(page).to have_css('#user-games > *', count: 2)
      expect(page).to have_css('#open-games > *', count: 2)
    end

    context 'when a user clicks on a game they joined' do
      it 'shows them the game' do
        visit games_path
        click_on 'Play'
        expect(current_path).to eq game_path(game.id)
      end
    end

    context 'when a user clicks on a game they have not joined' do
      it 'shows them that game and joins the game if they can join' do
        visit root_path
        click_on 'Join'
        expected_player_count = 1
        expect(current_path).to eq game_path(game2.id)
        expect(Player.where(game_id: game2.id).size).to eq expected_player_count
      end

      context 'when the user cannot join' do
        let(:game3) { create :game }
        before do
          2.times do
            game3.players.create(game_id: game3.id, user_id: user.id)
          end
        end
      end
    end
  end

  context 'when the history page is displayed' do
    let!(:game1) { create :finished_game }
    let!(:game2) { create :finished_game }
    let!(:user) { create :user }
    let!(:player) { create(:player_as_winner, user:, game: game1) }
    before do
      sign_in_as user
      visit games_history_path
    end
    it 'shows history of games' do
      expect(page).to have_content 'History'
      expect(page).to have_css '[data-testid="history-column"]', count: 1
      expect(page).to have_content user.name
    end
  end


  context 'when a users click new game button' do
    it 'shows the new game page' do
      sign_in_as user
      visit games_path
      click_on 'New Game'
      expect(page).to have_selector '#new-game-form'
    end
  end

  context 'when the user creates a new game' do
    it 'creates a new game and sends user to that page' do
      game_name = 'RoleModel'
      sign_in_as user
      expect do
        fill_in_new_game_form(3, game_name)
        expect(page).to have_content game_name
      end.to change(Game, :count).by 1
    end
  end

  context 'when a user goes a game they have not joined' do
    it 'redirects them to home page' do
      sign_in_as user
      game = create :game
      visit game_path(game.id)
      expect(current_path).to eq root_path
    end
  end

  context 'when the user inputs invalid data' do
    it 're-renders from with errors' do
      game_name = 'G'
      sign_in_as user
      fill_in_new_game_form(7, game_name)
      expect(page).to have_selector '#new-game-form'
      expect(page).to have_content 'is too short'
    end
  end

  def fill_in_new_game_form(game_size, game_name)
    visit new_game_path
    fill_in 'Name', with: game_name
    select 'Go Fish', from: 'Game type'
    fill_in 'Game size', with: game_size
    click_on 'Create Game'
  end
end

