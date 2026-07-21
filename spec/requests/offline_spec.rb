require 'rails_helper'

RSpec.describe 'Offline', type: :request do
  describe 'index' do
    it 'is reachable without authentication' do
      get offline_index_path
      expect(response).to have_http_status(:ok)
    end

    it 'renders the offline page' do
      get offline_index_path
      expected_content = 'offline'
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(expected_content)
    end
  end
end
