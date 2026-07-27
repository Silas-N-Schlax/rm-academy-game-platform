require 'rails_helper'

RSpec.describe 'Crazy Eights', type: :system do
  context 'when a Crazy Eights game has been dealt' do
    let!(:game) { create :game, type: 'CrazyEightsGame', game_size: 3, player_count: 3 }

    before do
      game.start!
      sign_in_as game.users.first
      visit game_path(game.reload)
    end

    it 'renders the dealt hand, stock, discard, and every opponent seat' do
      implementation = game.game_state
      your_player = implementation.find_player(game.users.first.id)
      opponents = implementation.players.reject { |player| player.id == game.users.first.id }

      expect(page).to have_content "Stock: #{implementation.deck.cards_left}"
      expect(page).to have_selector(data_test('hand-card'), count: your_player.hand.size)
      expect(page).to have_selector(data_test('discard-pile'))
      opponents.each { |opponent| expect(page).to have_content opponent.name }
    end

    it 'sends the player back to the home page' do
      find(data_test('board-back-button')).click
      expect(page).to have_current_path root_path
    end
  end

  context 'when it is not your turn' do
    let!(:game) { create :game, type: 'CrazyEightsGame', game_size: 2, player_count: 2 }

    before do
      game.start!
      sign_in_as game.users.last
      visit game_path(game.reload)
    end

    it 'renders hand cards as disabled' do
      expect(page).to have_selector "#{data_test('hand-card')}[disabled]", minimum: 1
    end
  end

  context 'when it is your turn' do
    let!(:game) { create :game, type: 'CrazyEightsGame', game_size: 2, player_count: 2 }

    before do
      game.start!
      game.game_state.discard.cards = [ CrazyEights::Card.new('7', 'Hearts') ]
      game.game_state.players.first.hand = [ CrazyEights::Card.new('7', 'Spades'), CrazyEights::Card.new('2', 'Clubs') ]
      game.save!
      sign_in_as game.users.first
      visit game_path(game.reload)
    end

    def choose_hand_card(card_id)
      find("label[for='#{card_id}']", visible: :all)
      page.execute_script("document.querySelector(\"label[for='#{card_id}']\").click()")
    end

    it 'plays the selected card onto the discard pile and persists the result', :js do
      choose_hand_card 'hand-card-7-Spades'
      find(data_test('discard-pile')).click

      expect(page).to have_selector(data_test('hand-card'), count: 1)
      game.reload
      expect(game.game_state.discard.top_card.rank).to eq '7'
      expect(game.game_state.discard.top_card.suit).to eq 'Spades'
      expect(game.game_state.players.first.hand.size).to eq 1
    end

    context 'when playing a wild 8' do
      before do
        game.game_state.players.first.hand = [ CrazyEights::Card.new('8', 'Spades') ]
        game.save!
        visit game_path(game.reload)
      end

      it 'opens the suit picker, then persists the chosen wild suit', :js do
        choose_hand_card 'hand-card-8-Spades'
        find(data_test('discard-pile')).click

        expect(page).to have_selector("#{data_test('wild-dialog')}[open]")
        find(data_test('wild-suit-option'), text: 'Diamonds').click

        expect(page).to have_selector(data_test('wild-suit-indicator'), text: 'Diamonds')
        game.reload
        expect(game.game_state.discard.top_card.rank).to eq '8'
        expect(game.game_state.wild_suit).to eq 'Diamonds'
      end
    end

    context 'when the player has no legal card to play' do
      before do
        game.game_state.deck.cards = [ CrazyEights::Card.new('2', 'Diamonds') ]
        game.game_state.discard.cards = [ CrazyEights::Card.new('9', 'Hearts') ]
        game.game_state.players.first.hand = [ CrazyEights::Card.new('2', 'Clubs') ]
        game.save!
        visit game_path(game.reload)
      end

      it 'draws from the stock pile and persists the new hand', :js do
        find(data_test('draw-pile')).click

        expect(page).to have_selector(data_test('hand-card'), count: 2)
        game.reload
        expect(game.game_state.players.first.hand.size).to eq 2
      end
    end

    context 'when the player has a legal card to play' do
      before do
        game.game_state.deck.cards = [ CrazyEights::Card.new('3', 'Diamonds') ]
        game.game_state.discard.cards = [ CrazyEights::Card.new('7', 'Hearts') ]
        game.game_state.players.first.hand = [ CrazyEights::Card.new('7', 'Spades') ]
        game.save!
        visit game_path(game.reload)
      end

      it 'does not draw when the draw pile is clicked', :js do
        find(data_test('draw-pile')).click

        expect(page).to have_selector(data_test('hand-card'), count: 1)
        game.reload
        expect(game.game_state.players.first.hand.size).to eq 1
      end
    end

    it 'shows the finished turn in the feed drawer once opened', :js do
      choose_hand_card 'hand-card-7-Spades'
      find(data_test('discard-pile')).click
      expect(page).to have_selector(data_test('hand-card'), count: 1)

      find(data_test('open-feed-button')).click

      within data_test('feed-drawer') do
        expect(page).to have_content 'You'
        expect(page).to have_content 'played a 7 of Spades'
      end
    end

    it 'announces what just happened in the action notice', :js do
      choose_hand_card 'hand-card-7-Spades'
      find(data_test('discard-pile')).click
      expect(page).to have_selector(data_test('hand-card'), count: 1)

      expect(page).to have_selector("#{data_test('action-notice')}.action-notice--active")
      within data_test('action-notice') do
        expect(page).to have_content 'You played a 7 of Spades'
      end
    end

    it "shows the opponent's last action on their seat tile", :js do
      opponent = game.game_state.players.last
      implementation = game.game_state
      implementation.results = [
        CrazyEights::TurnResult.new(current_player: opponent, card_played: CrazyEights::Card.new('9'),
                                     cards_drawn: [], occurred_at: Time.current)
      ]
      game.game_state = implementation
      game.save!
      visit game_path(game.reload)

      within(data_test('opponent-seat'), text: opponent.name) do
        expect(page).to have_content 'played a 9 of Spades'
      end
    end
  end

  context 'when the game has ended' do
    let!(:game) { create :game, type: 'CrazyEightsGame', game_size: 2, player_count: 2 }

    before do
      game.start!
      game.game_state.discard.cards = [ CrazyEights::Card.new('A') ]
      game.game_state.players.first.hand = [ CrazyEights::Card.new('A', 'Hearts') ]
      game.save!
      sign_in_as game.users.first
      visit game_path(game.reload)
    end

    def choose_hand_card(card_id)
      find("label[for='#{card_id}']", visible: :all)
      page.execute_script("document.querySelector(\"label[for='#{card_id}']\").click()")
    end

    it 'auto-opens the game-over modal with the winner and ranking', :js do
      choose_hand_card 'hand-card-A-Hearts'
      find(data_test('discard-pile')).click

      expect(page).to have_selector("#{data_test('game-over-modal')}[open]")
      within data_test('game-over-modal') do
        expect(page).to have_content "#{game.users.first.name} wins!"
        expect(page).to have_content 'Ranked by fewest cards left'
      end
    end
  end
end
