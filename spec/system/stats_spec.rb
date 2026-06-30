require 'rails_helper'
RSpec.describe 'Stats', type: :system do
  let!(:user) { create(:user) }
  before { log_in_user(user) }
  it 'shows the rules' do
    visit stats_path
    expect(page).to have_content 'Stats'
  end
end
