require 'rails_helper'
RSpec.describe 'Games', type: :system do
  let!(:user) { create(:user, password: '1234567', password_confirmation: '1234567') }

  it 'shows the sign-up page with no sidebar' do
    visit root_path
    expect(page).to have_selector data_test('login-form')
    expect(page).to_not have_selector data_test('sidebar')
  end

  context 'when the user signs in' do
    before do
      game = create :game
      create(:player, game:, user:)
    end
    it 'sends user to root path' do
      visit root_path
      expect(current_path).to eq new_session_path
      sign_in_as user
      visit root_path
      expect(page).to have_content 'Your Games'
      expect(page).to have_content 'Open Games'
    end
  end

  it 'sends back to login if given invalid input and no sidebar' do
    log_in_user build :user
    expect(page).to have_selector data_test('login-form')
  end

  it 'sends user to sign up page if they click link' do
    log_in_user build :user
    click_on 'Don\'t have an account?'
    expect(page).to have_selector data_test('signup-form')
  end

  it 'logs user our when sends to login page if logout' do
    sign_in_as user
    visit root_path
    click_on 'Log Out'
    expect(page).to have_selector data_test('login-form')
  end
end
