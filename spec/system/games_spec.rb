require 'rails_helper'
RSpec.describe 'Games', type: :system do
  let!(:user) { create(:user) }
  it 'shows the games index' do
    log_in_user(user)
    visit games_path
    expect(page).to have_content 'Your Games'
    expect(page).to have_content 'All Games'
  end

  it 'shows history of games' do
    log_in_user(user)
    visit games_history_path
    expect(page).to have_content 'History'
  end
end
