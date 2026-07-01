require 'rails_helper'
RSpec.describe 'Pages', type: :system do
  let!(:user) { create(:user) }
  it 'shows the rules' do
    sign_in_as user
    visit pages_rules_path
    expect(page).to have_content 'Rules'
    expect(page).to have_content 'Go Fish'
  end
end
