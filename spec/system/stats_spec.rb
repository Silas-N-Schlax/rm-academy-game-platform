require 'rails_helper'
RSpec.describe 'Stats', type: :system do
  it 'shows the stats' do
    user = create(:user)
    sign_in_as user
    visit stats_path
    expected_output = 'Stats'
    expect(page).to have_content expected_output
    expect(current_path).to eq stats_path
  end
end
