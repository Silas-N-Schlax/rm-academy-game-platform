require 'rails_helper'
RSpec.describe 'Pages', type: :system do
  it 'shows the rules' do
    visit pages_rules_path
    expect(page).to have_content 'Rules'
    expect(page).to have_content 'Go Fish'
  end
end
