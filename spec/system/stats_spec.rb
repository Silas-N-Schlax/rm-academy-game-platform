require 'rails_helper'
RSpec.describe 'Stats', type: :system do
  it 'shows the rules' do
    user = create(:user)
    sign_in_as user
    visit stats_path
    expect(page).to have_content 'Stats'
  end
end
