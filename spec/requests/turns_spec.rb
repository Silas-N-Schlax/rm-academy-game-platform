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

    context 'with a valid Rummy move' do
      let!(:game) { create :started_game, type: 'RummyGame' }
      before do
        game.start!
        implementation = game.game_state
        implementation.deck.cards = [ Rummy::Card.new('9') ]
        implementation.players.first.hand = [ Rummy::Card.new('2', 'Diamonds') ]
        game.save!
        sign_in_as game.users.first
      end

      it 'redirects to game_path(@game)' do
        post game_turns_path(game), params: { turn: { action: 'draw', source: 'stock' } }
        expect(response).to redirect_to game_path(game)
      end
    end

    context 'with an invalid Rummy move' do
      let!(:game) { create :started_game, type: 'RummyGame' }
      before do
        game.start!
        implementation = game.game_state
        implementation.deck.cards = []
        implementation.discard.cards = [ Rummy::Card.new('K') ]
        implementation.players.first.hand = [ Rummy::Card.new('2', 'Diamonds') ]
        game.save!
        sign_in_as game.users.first
      end

      it 'returns 422 for an illegal stock draw (empty stock, 1 discard card)' do
        post game_turns_path(game), params: { turn: { action: 'draw', source: 'stock' } }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns 422 when it is not the players turn' do
        sign_in_as game.users.last
        post game_turns_path(game), params: { turn: { action: 'draw', source: 'discard' } }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns 422 for an invalid meld' do
        game.game_state.players.first.hand = [ Rummy::Card.new('2', 'Diamonds'), Rummy::Card.new('5', 'Hearts'), Rummy::Card.new('9', 'Clubs') ]
        game.save!
        post game_turns_path(game), params: { turn: { action: 'draw', source: 'discard' } }
        post game_turns_path(game), params: { turn: { action: 'meld', card_ids: [ '2:Diamonds', '5:Hearts', '9:Clubs' ] } }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns 422 for a layoff attempted before melding' do
        game.game_state.melds = [ Rummy::Meld.new(cards: [ Rummy::Card.new('5', 'Hearts'), Rummy::Card.new('6', 'Hearts'), Rummy::Card.new('7', 'Hearts') ]) ]
        game.save!
        post game_turns_path(game), params: { turn: { action: 'draw', source: 'discard' } }
        post game_turns_path(game), params: { turn: { action: 'layoff', card_ids: [ '2:Diamonds' ], meld_index: 0 } }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns 422 when discarding the exact card just drawn from the discard pile' do
        post game_turns_path(game), params: { turn: { action: 'draw', source: 'discard' } }
        post game_turns_path(game), params: { turn: { action: 'discard', card_ids: [ 'K:Spades' ] } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'going out by discarding the just-drawn discard card when it is the only card left' do
      let!(:game) { create :started_game, type: 'RummyGame' }
      before do
        game.start!
        implementation = game.game_state
        implementation.deck.cards = []
        implementation.discard.cards = [ Rummy::Card.new('K', 'Spades') ]
        implementation.players.first.hand = []
        game.save!
        sign_in_as game.users.first
      end

      it 'redirects to game_path(@game) and ends the game' do
        post game_turns_path(game), params: { turn: { action: 'draw', source: 'discard' } }
        post game_turns_path(game), params: { turn: { action: 'discard', card_ids: [ 'K:Spades' ] } }
        expect(response).to redirect_to game_path(game)
        expect(game.reload.players.first.winner).to be true
      end

      it 'returns 422 for any further turn attempted after the game has ended' do
        post game_turns_path(game), params: { turn: { action: 'draw', source: 'discard' } }
        post game_turns_path(game), params: { turn: { action: 'discard', card_ids: [ 'K:Spades' ] } }

        post game_turns_path(game), params: { turn: { action: 'draw', source: 'stock' } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
