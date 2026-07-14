require 'rails_helper'
RSpec.describe 'Turns', type: :system do
  context 'when a valid GoFish turn is played' do
    let!(:game) { create :started_game }
    before do
      game.start!
      sign_in_as game.users.first
    end
    it 'displays a turn result' do
      visit game_path(game.reload)
      click_on 'Ask'
      expect(current_path).to eq game_path(game)
      expect(page).to have_selector('.game-feed__results')
    end

    context 'when an invalid GoFish request is given' do
      it 'returns 422' do
        post game_turns_path(game), params: { turn: { game: game, user: game.users.first, player: nil, rank: nil } }
        expect(response.status).to eq 422
      end
    end

    context 'when the game ends' do
      before do
        game.start!
        game_state = game.game_state
        game_state.deck.cards = []
        game_state.players.first.hand = [ GoFish::Card.new('A'), GoFish::Card.new('A'), GoFish::Card.new('A') ]
        game_state.players.last.hand = [ GoFish::Card.new('A') ]
        game.save!
      end
      it 'display a game over view' do
        expected_content = 'Game Over'
        visit game_path(game)
        click_on 'Ask'
        expect(page).to have_content expected_content
        expect(page).to have_content game.users.first.name
      end
    end
  end

  context 'when a valid CrazyEights turn is played' do
    let!(:game) { create :started_game, type: 'CrazyEightsGame' }
    before do
      game.start!
      implementation = game.game_state
      implementation.players.first.hand = [ CrazyEights::Card.new('J') ]
      implementation.discard.cards = [ CrazyEights::Card.new('2') ]
      game.save
      sign_in_as game.users.first
    end
    it 'displays a turn result' do
      visit game_path(game.reload)
      find('.playing-card--large', match: :first).click
      expect(current_path).to eq game_path(game)
      expect(page).to have_selector('.game-feed__result')
    end

    context 'when an invalid GoFish request is given' do
      it 'returns 422' do
        post game_turns_path(game), params: { turn: { game: game, user: game.users.first, suit: nil, rank: nil } }
        expect(response.status).to eq 422
      end
    end

    context 'when an 8 is tried to play' do
      let!(:game) { create :started_game, type: 'CrazyEightsGame' }
      before do
        game.start!
        game_state = game.game_state
        game_state.discard.cards = [ CrazyEights::Card.new('A') ]
        game_state.players.first.hand = [ CrazyEights::Card.new('8', 'Hearts'), CrazyEights::Card.new('8')  ]
        game.save!
        visit game_path(game)
        find('.playing-card--large', match: :first).click
      end
      it 'allows player to play card' do
        expected_modal_content = 'Oooh, a wild.'
        expect(page).to have_content expected_modal_content
        click_button "Play My Wild", match: :first
        expect(current_path).to eq game_path(game)
        expect(page).to have_selector('#discard-top-card-rank-8')
      end
    end

    context 'when a card is requested' do
       let!(:game) { create :started_game, type: 'CrazyEightsGame' }
      before do
        game.start!
        game_state = game.game_state
        game_state.discard.cards = [ CrazyEights::Card.new('A') ]
        game_state.players.first.hand = [ CrazyEights::Card.new('2', 'Hearts'), CrazyEights::Card.new('3', 'Hearts')  ]
        game_state.deck.cards = [ CrazyEights::Card.new('A', 'Clubs'), CrazyEights::Card.new('A', 'Hearts') ]
        game.save!
        visit game_path(game)
      end
      it 'gives player card when they can draw' do
        find('.playing-card--x-large', match: :first).click
        expected_card_count = 3
        expect(current_path).to eq game_path(game)
        expect(page.all(:css, '.playing-card--large').count).to eq expected_card_count
      end

      it 'does not give player cards when they cannot draw' do
        game.game_state.discard.cards = [ CrazyEights::Card.new('A', 'Hearts') ]
        game.save!
        find('.playing-card--x-large', match: :first).click
        expected_card_count = 2
        expect(current_path).to eq game_path(game)
        expect(page.all(:css, '.playing-card--large').count).to eq expected_card_count
      end
    end

    context 'when the game ends' do
      before do
        game.start!
        game_state = game.game_state
        game_state.discard.cards = [ GoFish::Card.new('A') ]
        game_state.players.first.hand = [ GoFish::Card.new('A', 'Hearts') ]
        game.save!
      end
      it 'display a game over view' do
        expected_content = 'Game Over'
        visit game_path(game)
        find('.playing-card--large', match: :first).click
        expect(page).to have_content expected_content
        expect(page).to have_content game.users.first.name
      end
    end
  end
end
