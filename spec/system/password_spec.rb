require 'rails_helper'
RSpec.describe 'Games', type: :system do
  let!(:user) { create(:user) }
  it 'shows forgot password page if clicked' do
    visit root_path
    click_on 'Forgot password?'
    expect(current_path).to eq new_password_path
    expect(page).to have_content 'Forgot your password?'
  end
end
