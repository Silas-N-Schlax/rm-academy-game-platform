require 'rails_helper'

RSpec.describe 'Authentication', type: :request do
  describe 'unauthenticated request to a protected action' do
    it 'redirects to new_session_path' do
      get new_game_path
      expect(response).to have_http_status(302)
    end

    it 'stores request.url in session[:return_to_after_authenticating]' do
      get new_game_path
      expect(session[:return_to_after_authenticating]).to eq new_game_url
    end
  end

  describe 'valid signed cookie' do
    it 'succeeds and sets Current.session' do
      user = create :user
      sign_in_as user
      expect(Current.session).to_not be_nil
    end
  end

  describe 'missing cookie' do
    before do
      user = create :user
      sign_in_as user
      delete session_path
    end
    it 'is unauthenticated with no DB lookup' do
      get root_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe 'stale session (row deleted, cookie present)' do
    before do
      user = create :user
      sign_in_as user
      user.sessions.destroy_all
    end
    it 'is unauthenticated' do
      get root_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe 'allow_unauthenticated_access' do
    it 'permits a skip-listed action with no session' do
      get new_user_path
      expect(response).to have_http_status(:ok)
    end

    it 'still blocks a non-permitted action on the same controller' do
      get users_show_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe 'return_to round-trip' do
    it 'lands on the originally-requested URL after signing in' do
      user = create :user
      get new_game_path
      post session_path, params: { session: { email_address: user.email_address, password: 'password' } }
      expect(response).to redirect_to(new_game_url)
    end
    it 'clears the stored return_to session key afterward' do
      user = create :user
      get new_game_path
      post session_path, params: { session: { email_address: user.email_address, password: 'password' } }
      expect(session[:return_to_after_authenticating]).to be_nil
    end
  end
end
