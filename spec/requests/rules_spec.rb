require 'rails_helper'

RSpec.describe 'Rules', type: :request do
  describe 'index' do
    it 'requires authentication' do
      get rules_path
      expect(response).to redirect_to new_session_path
    end

    it 'lists both games' do
      user = create :user
      sign_in_as user
      get rules_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Go Fish')
      expect(response.body).to include('Crazy Eights')
    end
  end

  describe 'show' do
    it 'renders the given game rules' do
      user = create :user
      sign_in_as user
      get rule_path('crazy-eights')
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Crazy Eights')
    end

    it 'raises for an unknown game slug' do
      user = create :user
      sign_in_as user
      expect { get rule_path('checkers') }.to raise_error(DataFor::RecordNotFound)
    end
  end
end
