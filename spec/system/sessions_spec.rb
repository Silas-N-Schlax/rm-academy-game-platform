require 'rails_helper'
RSpec.describe 'Games', type: :system do
  let!(:user) { create(:user, password: '1234567', confirm_password: '1234567') }
  it 'sends user to root path when given valid input' do
    visit root_path
    expect(current_path).to eq new_session_path
    log_in_user(user)
    expect(current_path).to eq root_path
    expect(page).to have_content 'Your Games'
    expect(page).to have_content 'All Games'
  end

  it 'sends back to login if given invalid input' do
    log_in_user build :user
    expect(current_path).to eq new_session_path
  end

  it 'logs user our when sends to login page if logout' do
    log_in_user(user)
    click_on 'Log Out'
    expect(current_path).to eq new_session_path
  end
end
