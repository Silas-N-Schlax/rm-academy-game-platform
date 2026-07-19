require 'rails_helper'

RSpec.describe 'Offline', type: :system do
  let!(:user) { create :user }
  context 'when a user visits the offline route' do
    before do
      sign_in_as user
    end
    it 'displays offline page when you visit the route' do
      visit offline_index_path
      expected_content = 'Offline'
      non_expected_content = 'Games'
      expect(page).to have_content expected_content
      expect(page).to_not have_content non_expected_content
    end
  end

  context 'when there is no internet connection', :chrome do
    before do
      visit root_path
      wait_for_service_worker_control

      emulate_worker_network(offline: true)
    end
    it 'displays offline page' do
      visit root_path
      expected_content = 'Offline'
      expect(page).to have_content expected_content
    end
  end
end
