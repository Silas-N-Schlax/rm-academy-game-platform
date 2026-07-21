require 'rails_helper'

RSpec.describe 'Games', type: :request do
  describe 'create' do
    before do
      user = create :user
      sign_in_as user
    end
    context 'with valid params' do
      it 'saves the new game, adds the creator as a player, and redirects to game_path' do
        expect { post games_path, params: { game: attributes_for(:game) } }
          .to change(Game, :count).by(1)
        expect(response).to redirect_to(game_path(Game.all.first))
      end
    end

    context 'with invalid params' do
      it 'returns 422 and re-renders new' do
        expect { post games_path, params: { game: { test: false } } }
          .to change(Game, :count).by(0)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'show' do
    context 'when the user is not in the game' do
      before do
        user = create :user
        sign_in_as user
      end
      it 'redirects to root' do
        game = create :game
        get game_path(game)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'new/index' do
    it 'requires authentication' do
      get root_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
