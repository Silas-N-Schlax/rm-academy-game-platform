require 'rails_helper'

RSpec.describe 'Users', type: :system do
  it 'shows the sign-up page' do
    visit new_user_path
    expected_selector = '.simple-page__form'
    expect(page).to have_selector expected_selector
  end

  it 'sign-up and shows home screen' do
    visit new_user_path
    expect do
      fill_in_signup_form
      expect(page).to have_current_path root_path
    end.to change(User, :count).by 1
  end

  def fill_in_signup_form
    fill_in "name", with: 'Player1'
    fill_in "email_address", with: 'example@example.com'
    fill_in "password", with: 'password'
    fill_in 'confirm_password', with: 'password'
    click_button "Sign Up"
  end
end
