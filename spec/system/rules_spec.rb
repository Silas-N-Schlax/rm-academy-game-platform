require 'rails_helper'

RSpec.describe 'Rules', type: :system do
  let!(:user) { create(:user) }

  it 'lists both games with their type and a link to their rules' do
    sign_in_as user
    visit rules_path
    expect(page).to have_content 'Go Fish'
    expect(page).to have_content 'Crazy Eights'
    expect(page).to have_content('Card Game', count: 2)
    click_on 'View rules', match: :first
    expect(page).to have_content 'The Pack'
  end

  it 'shows the go fish rules and a link back to the rules index' do
    sign_in_as user
    visit rule_path('go-fish')
    expect(page).to have_content 'Go Fish'
    expect(page).to have_content 'Ending the Game'
    expect(page).to have_content 'Card Game'
    find('[data-testid="back-to-rules"]').click
    expect(current_path).to eq rules_path
  end

  it 'shows the crazy eights rules' do
    sign_in_as user
    visit rule_path('crazy-eights')
    expect(page).to have_content 'Crazy Eights'
    expect(page).to have_content 'wild'
  end
end
