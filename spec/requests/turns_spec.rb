require 'rails_helper'

RSpec.describe 'Turns', type: :request do
  describe 'create' do
    context 'with an invalid Go Fish move' do
      let!(:game) { create :started_game }
      before do
        game.start!
        sign_in_as game.users.first
      end
      it 'returns 422 for a nil player/rank' do
        post game_turns_path(game), params: { turn: { player: nil, rank: nil } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'with an invalid Crazy Eights move' do
      let!(:game) { create :started_game, type: 'CrazyEightsGame' }
      before do
        game.start!
        sign_in_as game.users.first
      end
      it 'returns 422 for an invalid move' do
        post game_turns_path(game), params: { turn: { rank: nil, suit: nil } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'with a valid move' do
      let!(:game) { create :started_game }
      before do
        game.start!
        implementation = game.game_state
        implementation.players.first.hand = [ GoFish::Card.new('A'), GoFish::Card.new('K') ]
        implementation.players.last.hand = [ GoFish::Card.new('A') ]
        game.save!
        sign_in_as game.users.first
      end
      it 'redirects to game_path(@game)' do
        opponent = game.users.last
        post game_turns_path(game), params: { turn: { player: opponent.id, rank: 'A'  } }
        expect(response).to redirect_to game_path(game)
      end
    end

    context 'when unauthenticated' do
      let(:game) { create :started_game }
      before { game.start! }
      it 'redirects to sign-in' do
        post game_turns_path(game), params: { turn: { player: 1, rank: 'A' } }
        expect(response).to redirect_to new_session_path
      end
    end
  end
end
