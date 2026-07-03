require 'rails_helper'

RSpec.describe 'Users', type: :system do
  it 'shows the sign-up page with no sidebar' do
    visit new_user_path
    expected_selector = '.simple-page__form'
    expected_sidebar_selector = '.op-page__sidebar'
    expect(page).to have_selector expected_selector
    expect(page).to_not have_selector expected_sidebar_selector
  end

  it 'sign-up and shows home screen' do
    visit new_user_path
    expect do
      fill_in_signup_form
      expect(page).to have_current_path root_path
    end.to change(User, :count).by 1
  end

  it 'sends user to login page when they click on link' do
    visit new_user_path
    click_on 'Have an account?'
    expected_selector = '#login-form'
    expect(page).to have_selector expected_selector
  end

  it 'shows profile page' do
    user = create(:user)
    sign_in_as user
    visit root_path

    click_on 'Profile'
    expect(page).to have_content user.name
    expect(page).to have_content user.email_address
  end

  def fill_in_signup_form
    fill_in "Name", with: 'Player1'
    fill_in "Email address", with: 'example@example.com'
    fill_in "Password", with: 'password'
    fill_in 'Confirm password', with: 'password'
    click_on 'Sign Up'
  end
end
