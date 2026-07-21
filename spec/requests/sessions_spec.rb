require 'rails_helper'

RSpec.describe 'Sessions', type: :request do
  describe 'create' do
    context 'with valid credentials' do
      it 'sets the signed session cookie and redirects to after_authentication_url' do
        user = create :user
        get new_game_path
        post session_path, params: { session: { email_address: user.email_address, password: 'password' } }
        expect(response).to redirect_to(new_game_url)
      end
    end

    context 'with invalid credentials' do
      before do
        user = create :user
        get new_game_path
        post session_path, params: { session: { email_address: user.email_address, password: 'password1' } }
      end
      it 'returns 422 and re-renders new' do
        expected_content = 'Sign In'
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include expected_content
      end

      it 'does not set the session cookie' do
        expect(response.cookies['session_id']).to be_blank
      end
    end
  end

  describe 'destroy' do
    let!(:user) { create :user }
    before { sign_in_as user }
    it 'destroys the Session row' do
      expect {
        delete session_path
      }.to change(Session, :count).by(-1)
    end

    it 'deletes the session cookie' do
      delete session_path
      expect(cookies[:session_id]).to be_blank
    end

    it 'responds 303 See Other' do
      delete session_path
      expect(response).to have_http_status(303)
      expect(response).to redirect_to new_session_path
    end
  end
end
