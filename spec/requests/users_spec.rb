require 'rails_helper'

RSpec.describe 'Users', type: :request do
  describe 'create' do
    context 'with valid params' do
      it 'saves the user, signs them in, and redirects to root' do
        expect {
          post users_path, params: { user: attributes_for(:user) }
        }.to change(User, :count).by(1)
        expect(response).to redirect_to(root_path)
        expect(response.cookies['session_id']).to be_present
      end
    end

    context 'with invalid params' do
      it 'returns 422, re-renders new with an alert, and does not sign in' do
         expect {
          post users_path, params: { user: { email_address: '' } }
        }.to_not change(User, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(flash[:alert]).to eq('Something went wrong')
        expect(response.cookies['session_id']).to be_nil
      end
    end
  end

  describe 'authentication requirements' do
    let(:user) { create :user }
    it 'reaches new/create without auth' do
      get new_session_path
      expect(response).to have_http_status(:ok)
    end

    it 'requires auth for show/edit/update' do
      get edit_user_path(user)
      expect(response).to have_http_status(302)
      get users_show_path(user)
      expect(response).to have_http_status(302)
      patch user_path(user), params: { user: { name: 'hello world' } }
      expect(response).to have_http_status(302)
    end
  end

  describe 'update' do
    let(:user) { create :user }
    before { sign_in_as user }
    context 'with valid profile params' do
      it 'updates current_user and redirects to users_show_path' do
        patch user_path(user), params: { user: { name: 'hello world' } }
        expect(response).to redirect_to users_show_url
      end
    end

    context 'with invalid params' do
      it 'returns 422 and re-renders edit in the modal layout' do
        patch user_path(user), params: { user: { name: '' } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('turbo-frame id="modal"')
      end
    end
  end

  describe 'edit/show' do
    let(:user) { create :user }
    let(:user1) { create :user }
    before { sign_in_as user }
    it 'loads current_user regardless of any param id' do
      get users_show_path(user1)
      expect(response.body).to include user.name
    end
  end
end
