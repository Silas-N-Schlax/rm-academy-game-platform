require 'rails_helper'
RSpec.describe 'Games', type: :system do
  let!(:user) { create(:user) }
  it 'shows the games index' do
    sign_in_as user
    visit games_path
    expect(page).to have_content 'Your Games'
    expect(page).to have_content 'All Games'
  end

  it 'shows history of games' do
    sign_in_as user
    visit games_history_path
    expect(page).to have_content 'History'
  end

  context 'when a users click new game button' do
    it 'shows the new game page' do
      sign_in_as user
      visit games_path
      click_on 'New Game'
      expect(page).to have_selector '#new-game-form'
    end

    it 'fills in form and creates a new game' do
      game_name = 'RoleModel'
      sign_in_as user
      fill_in_new_game_form(3, game_name)
      expect(page).to have_content game_name
    end

    it 'fills in form with invalid data and it re-renders form with errors' do
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
