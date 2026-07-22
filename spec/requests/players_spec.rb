require 'rails_helper'

RSpec.describe 'Players', type: :request do
  describe 'create' do
    let!(:user) { create :user }
    before { sign_in_as user }

    context 'when the game has already started' do
      let!(:game) { create(:started_game, player_count: 1) }
      it 'does not add the user and redirects to root' do
        expect { post game_players_path(game) }.to_not change(Player, :count)
        expect(response).to redirect_to root_path
      end
    end

    context 'when the user is already in the game' do
      let!(:game) { create(:game, game_size: 3, player_count: 1) }
      before { create(:player, game:, user:) }
      it 'does not add a duplicate player and redirects to root' do
        expect { post game_players_path(game) }.to_not change(Player, :count)
        expect(response).to redirect_to root_path
      end
    end

    context 'when the game is open and not started' do
      let!(:game) { create(:game, player_count: 1) }
      it 'adds the user as a player and redirects to the game' do
        expect { post game_players_path(game) }.to change(Player, :count).by(1)
        expect(response).to redirect_to game_path(game)
      end
    end
  end
end
