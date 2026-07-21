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

    context 'when a non-player goes to game route' do
      let!(:game) { create :game }
      let!(:user) { create :user }
      before { sign_in_as user }
      it 'does not start the game' do
        get game_path(game)
        expect(response).to redirect_to root_path
        expect(Game.all.first.game_state).to be_nil
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

  describe 'join' do
    let!(:user) { create :user }
    before { sign_in_as user }
    context 'when the game has already started' do
      let!(:game) { create(:started_game, player_count: 1) }
      it 'does not add the user and redirects to root' do
        expect { post join_path(game) }.to_not change(Player, :count)
        expect(response).to redirect_to root_path
      end
    end

    context 'when the user is already in the game' do
      let!(:game) { create(:game, game_size: 3, player_count: 1) }
      before { create(:player, game:, user:) }
      it 'does not add a duplicate player and redirects to root' do
        expect { post join_path(game) }.to_not change(Player, :count)
        expect(response).to redirect_to root_path
      end
    end

    context 'when teh game is open and not started' do
      let!(:game) { create(:game, player_count: 1) }
      it 'adds the user as a player and redirects to the game' do
        expect { post join_path(game) }.to change(Player, :count).by(1)
        expect(response).to redirect_to game_path(game)
      end
    end
  end
end
