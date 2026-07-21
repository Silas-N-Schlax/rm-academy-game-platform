require 'rails_helper'

RSpec.describe 'Pages', type: :request do
  describe 'rules' do
    it 'requires authentication' do
      get pages_rules_path
      expect(response).to redirect_to new_session_path
    end

    it 'renders the rules page' do
      user = create :user
      sign_in_as user
      get pages_rules_path
      expected_content = 'rules'
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(expected_content)
    end
  end
end
