require 'rails_helper'
RSpec.describe 'Games', type: :system do
  let!(:user) { create(:user, password: '1234567', confirm_password: '1234567') }
  let(:sidebar_selector) { '.op-page__sidebar' }

  it 'shows the sign-up page with no sidebar' do
    visit root_path
    expected_selector = '.simple-page__form'
    expect(page).to have_selector expected_selector
    expect(page).to_not have_selector sidebar_selector
  end

  it 'sends user to root path when given valid input with no sidebar' do
    visit root_path
    expect(current_path).to eq new_session_path
    sign_in_as user
    visit root_path
    expect(page).to have_content 'Your Games'
    expect(page).to have_content 'Open Games'
  end

  it 'sends back to login if given invalid input and no sidebar' do
    log_in_user build :user
    expected_selector = '#login-form'
    expect(page).to have_selector expected_selector
  end

  it 'sends user to sign up page if they click link' do
    log_in_user build :user
    scroll_link_into_view('Don\'t have an account?')
    click_on 'Don\'t have an account?'
    expected_selector = '#signup-form'
    expect(page).to have_selector expected_selector
  end

  it 'logs user our when sends to login page if logout' do
    sign_in_as user
    visit root_path
    click_on 'Log Out'
    expected_selector = '#login-form'
    expect(page).to have_selector expected_selector
  end
end
