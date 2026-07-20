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

  context 'when user is on the profile page' do
    let!(:user) { create :user }
    before do
      sign_in_as user
    end
    it 'shows profile page' do
      visit root_path

      click_on 'Profile'
      expect(page).to have_content user.name
      expect(page).to have_content user.email_address
    end

    it 'shows edit page' do
      visit users_show_path
      click_on 'Edit Profile'
      expect(current_path).to eq edit_user_path(user)
      expected_content = 'Edit Your Profile'
      expect(page).to have_content expected_content
    end

    it 'shows state when country is selected', :js do
      visit edit_user_path(user)
      select 'United States', from: 'Country'
      expected_content = 'State'
      expect(page).to have_content expected_content
      select 'North Carolina', from: 'State'
    end

    it 'when the user updates their country for the first time it shows on their profile' do
      visit edit_user_path(user)
      select 'United States', from: 'Country'
      click_on "Edit Profile"
      expected_content = 'US'
      expect(page).to have_content expected_content
    end

    it 'does not have extra empty fields if there is no data' do
       visit users_show_path(user)
       expected_content = 'Country'
       expect(page).to_not have_content expected_content
    end
  end


  def fill_in_signup_form
    fill_in "Name", with: 'Player1'
    fill_in "Email address", with: 'example@example.com'
    fill_in "Password", with: 'password', match: :first
    fill_in 'Password confirmation', with: 'password'
    click_on 'Sign Up'
  end
end
