require 'rails_helper'

RSpec.describe 'Offline', type: :system do
  let!(:user) { create :user }
  context 'when a user visits the offline route' do
    before do
      sign_in_as user
    end

    it 'displays offline page when you visit the route' do
      visit offline_index_path
      expected_content = 'offline'
      non_expected_content = 'Games'
      expect(page).to have_content expected_content
      expect(page).to_not have_content non_expected_content
    end

    it 'shows the logo, offline message, and a try again button' do
      visit offline_index_path

      expect(page).to have_css("img[src='/logo.png']")
      expect(page).to have_content "You're offline"
      expect(page).to have_button 'Try again'
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
      expected_content = 'offline'
      expect(page).to have_content expected_content
      emulate_worker_network(offline: false)
    end

    it 'precaches the assets needed to render the offline page styled' do
      cached_urls = page.evaluate_async_script(<<~JS)
        var callback = arguments[arguments.length - 1];
        caches.open('v2').then((cache) => cache.keys()).then((requests) => {
          callback(requests.map((request) => request.url));
        });
      JS

      expect(cached_urls).to include(a_string_ending_with('/offline'))
      expect(cached_urls).to include(a_string_matching(%r{optics\+lucide_icons\.min\.css}))
      expect(cached_urls).to include(a_string_matching(%r{cloud-off\.svg}))
      expect(cached_urls).to include(a_string_ending_with('/logo.png'))
      expect(cached_urls).to include(a_string_ending_with('/icon.png'))
      emulate_worker_network(offline: false)
    end
  end
end
