require 'rails_helper'
RSpec.describe 'Stats', type: :system do
  it 'shows the rules' do
    visit stats_path
    expect(page).to have_content 'Stats'
  end
end
