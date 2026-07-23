require 'rails_helper'

RSpec.describe 'Rummy gameplay', type: :system do
  let!(:game) { create :game, type: 'RummyGame' }

  before { game.start! }

  def check_hand_card(card_id)
    find("label[for='#{card_id}']", visible: :all)
    page.execute_script("document.querySelector(\"label[for='#{card_id}']\").click()")
  end

  describe 'reloading an already-finished game', :js do
    before do
      implementation = game.game_state
      implementation.players.first.hand = []
      implementation.players.last.hand = [ Rummy::Card.new('K', 'Spades') ]
      game.game_state = implementation
      game.finished_at = Time.current
      game.save!
      game.players.first.update!(winner: true)
      sign_in_as game.users.first
    end

    it 'auto-displays the game-over modal on a fresh page load, and it can still be closed and reopened' do
      visit game_path(game)

      expect(page).to have_selector('#game-over-modal[open]')
      within('#game-over-modal') { expect(page).to have_content "#{game.users.first.name} wins!" }

      click_button 'Close'

      expect(page).not_to have_selector('#game-over-modal[open]')

      click_button 'View results'

      expect(page).to have_selector('#game-over-modal[open]')
    end
  end

  describe 'meld/discard buttons before drawing', :js do
    before do
      implementation = game.game_state
      implementation.players.first.hand = [
        Rummy::Card.new('7', 'Spades'), Rummy::Card.new('7', 'Hearts'), Rummy::Card.new('7', 'Diamonds')
      ]
      implementation.deck.cards = [ Rummy::Card.new('9', 'Diamonds') ]
      implementation.discard.cards = [ Rummy::Card.new('K', 'Spades') ]
      game.game_state = implementation
      game.save!
      sign_in_as game.users.first
      visit game_path(game)
    end

    it 'disables Meld and Discard and shows a draw-first icon until a card is drawn' do
      expect(page).to have_button('Meld', disabled: true)
      expect(page).to have_button('Discard', disabled: true)
      expect(page).to have_selector('[data-game-board-target="meldDrawIcon"]:not([hidden])', visible: :all)

      click_on 'Draw from stock'
      expect(page).to have_selector('.game-board__hand .playing-card', count: 4)
      check_hand_card 'hand-card-7-Spades'
      check_hand_card 'hand-card-7-Hearts'
      check_hand_card 'hand-card-7-Diamonds'

      expect(page).to have_button('Meld', disabled: false)
      expect(page).to have_selector('[data-game-board-target="meldDrawIcon"][hidden]', visible: :all)
    end
  end

  describe 'drawing from the stock' do
    before do
      implementation = game.game_state
      implementation.players.first.hand = [ Rummy::Card.new('2', 'Clubs') ]
      implementation.deck.cards = [ Rummy::Card.new('9', 'Diamonds') ]
      implementation.discard.cards = [ Rummy::Card.new('K', 'Spades') ]
      game.game_state = implementation
      game.save!
      sign_in_as game.users.first
      visit game_path(game)
    end

    it 'adds the top stock card to the hand and reduces the stock count' do
      expect(page).to have_content 'Stock: 1'

      click_on 'Draw from stock'

      expect(page).to have_content 'Stock: 0'
      expect(page).to have_selector('.game-board__hand .playing-card', count: 2)
    end
  end

  describe 'drawing from the discard pile' do
    before do
      implementation = game.game_state
      implementation.players.first.hand = [ Rummy::Card.new('2', 'Clubs') ]
      implementation.deck.cards = [ Rummy::Card.new('9', 'Diamonds') ]
      implementation.discard.cards = [ Rummy::Card.new('K', 'Spades') ]
      game.game_state = implementation
      game.save!
      sign_in_as game.users.first
      visit game_path(game)
    end

    it 'adds the top discard card to the hand' do
      click_on 'Draw from discard'

      expect(page).to have_selector('.game-board__hand .playing-card', count: 2)
      expect(page).to have_css("#hand-card-K-Spades")
    end
  end

  describe 'stock recycling' do
    before do
      implementation = game.game_state
      implementation.players.first.hand = [ Rummy::Card.new('2', 'Clubs') ]
      implementation.deck.cards = []
      implementation.discard.cards = [ Rummy::Card.new('Q', 'Hearts'), Rummy::Card.new('J', 'Clubs'), Rummy::Card.new('10', 'Diamonds') ]
      game.game_state = implementation
      game.save!
      sign_in_as game.users.first
      visit game_path(game)
    end

    it 'reshuffles the discard pile (minus its top card) into the stock, then draws' do
      click_on 'Draw from stock'

      expect(page).to have_content 'Stock: 1'
      expect(page).to have_css("[src*='queen_of_hearts']")
      expect(page).to have_selector('.game-board__hand .playing-card', count: 2)
    end
  end

  describe 'melding a valid set' do
    before do
      implementation = game.game_state
      implementation.players.first.hand = [
        Rummy::Card.new('7', 'Spades'), Rummy::Card.new('7', 'Hearts'), Rummy::Card.new('7', 'Diamonds'),
        Rummy::Card.new('9', 'Clubs')
      ]
      implementation.deck.cards = [ Rummy::Card.new('2', 'Diamonds') ]
      implementation.discard.cards = [ Rummy::Card.new('K', 'Spades') ]
      game.game_state = implementation
      game.save!
      sign_in_as game.users.first
      visit game_path(game)
      click_on 'Draw from stock'
    end

    it 'moves the three cards from the hand onto a new meld on the table' do
      check 'hand-card-7-Spades'
      check 'hand-card-7-Hearts'
      check 'hand-card-7-Diamonds'

      click_button 'Meld'

      expect(page).to have_selector('.game-board__melds .game-board__meld', count: 1)
      expect(page).to have_selector('.game-board__hand .playing-card', count: 2)
    end
  end

  describe 'melding a valid run' do
    before do
      implementation = game.game_state
      implementation.players.first.hand = [
        Rummy::Card.new('5', 'Hearts'), Rummy::Card.new('6', 'Hearts'), Rummy::Card.new('7', 'Hearts'),
        Rummy::Card.new('9', 'Clubs')
      ]
      implementation.deck.cards = [ Rummy::Card.new('2', 'Diamonds') ]
      implementation.discard.cards = [ Rummy::Card.new('K', 'Spades') ]
      game.game_state = implementation
      game.save!
      sign_in_as game.users.first
      visit game_path(game)
      click_on 'Draw from stock'
    end

    it 'moves the three consecutive same-suit cards onto a new meld on the table' do
      check 'hand-card-5-Hearts'
      check 'hand-card-6-Hearts'
      check 'hand-card-7-Hearts'

      click_button 'Meld'

      expect(page).to have_selector('.game-board__melds .game-board__meld', count: 1)
      expect(page).to have_selector('.game-board__hand .playing-card', count: 2)
    end
  end

  describe 'laying off a card onto an existing meld', :js do
    before do
      implementation = game.game_state
      implementation.melds = [ Rummy::Meld.new(cards: [
        Rummy::Card.new('K', 'Spades'), Rummy::Card.new('K', 'Hearts'), Rummy::Card.new('K', 'Diamonds')
      ]) ]
      implementation.players.first.has_melded = true
      implementation.players.first.hand = [ Rummy::Card.new('K', 'Clubs'), Rummy::Card.new('9', 'Clubs') ]
      implementation.deck.cards = [ Rummy::Card.new('2', 'Diamonds') ]
      implementation.discard.cards = [ Rummy::Card.new('3', 'Spades') ]
      game.game_state = implementation
      game.save!
      sign_in_as game.users.first
      visit game_path(game)
      click_on 'Draw from stock'
      expect(page).to have_selector('.game-board__hand .playing-card', count: 3)
    end

    it 'moves the checked card onto the clicked meld and shrinks the hand' do
      check_hand_card 'hand-card-K-Clubs'
      expect(page).to have_field('hand-card-K-Clubs', checked: true)
      find('.game-board__meld').click

      expect(page).to have_selector('.game-board__meld img', count: 4)
      expect(page).to have_selector('.game-board__hand .playing-card', count: 2)
    end
  end

  describe 'a full meld disables its lay-off button', :js do
    before do
      implementation = game.game_state
      implementation.melds = [ Rummy::Meld.new(cards: [
        Rummy::Card.new('K', 'Spades'), Rummy::Card.new('K', 'Hearts'),
        Rummy::Card.new('K', 'Diamonds'), Rummy::Card.new('K', 'Clubs')
      ]) ]
      implementation.players.first.has_melded = true
      implementation.players.first.hand = [ Rummy::Card.new('9', 'Clubs') ]
      implementation.deck.cards = [ Rummy::Card.new('2', 'Diamonds') ]
      implementation.discard.cards = [ Rummy::Card.new('3', 'Spades') ]
      game.game_state = implementation
      game.save!
      sign_in_as game.users.first
      visit game_path(game)
      click_on 'Draw from stock'
    end

    it 'renders the full meld button as disabled' do
      expect(page).to have_selector('.game-board__meld[disabled]')
    end
  end

  describe 'discarding and passing the turn' do
    before do
      implementation = game.game_state
      implementation.players.first.hand = [ Rummy::Card.new('2', 'Clubs'), Rummy::Card.new('3', 'Diamonds') ]
      implementation.deck.cards = [ Rummy::Card.new('9', 'Hearts') ]
      implementation.discard.cards = [ Rummy::Card.new('K', 'Spades') ]
      game.game_state = implementation
      game.save!
      sign_in_as game.users.first
      visit game_path(game)
      click_on 'Draw from stock'
    end

    it 'discards the checked card and hands the turn to the next player' do
      check 'hand-card-2-Clubs'

      click_button 'Discard'

      expect(page).to have_content "#{game.users.last.name}'s Turn"
      expect(page).to have_selector('.game-board__hand .playing-card', count: 2)
    end
  end

  describe 'going out by melding away the entire hand' do
    before do
      implementation = game.game_state
      implementation.players.first.hand = [
        Rummy::Card.new('7', 'Spades'), Rummy::Card.new('7', 'Hearts'), Rummy::Card.new('7', 'Diamonds')
      ]
      implementation.deck.cards = [ Rummy::Card.new('7', 'Clubs') ]
      implementation.discard.cards = [ Rummy::Card.new('K', 'Spades') ]
      game.game_state = implementation
      game.save!
      sign_in_as game.users.first
      visit game_path(game)
      click_on 'Draw from stock'
    end

    it 'ends the game immediately, with no discard required' do
      check 'hand-card-7-Spades'
      check 'hand-card-7-Hearts'
      check 'hand-card-7-Diamonds'
      check 'hand-card-7-Clubs'

      click_button 'Meld'

      expect(page).to have_content "#{game.users.first.name} wins!"
    end
  end

  describe 'going out via discard' do
    before do
      implementation = game.game_state
      implementation.players.first.hand = [
        Rummy::Card.new('7', 'Spades'), Rummy::Card.new('7', 'Hearts'), Rummy::Card.new('7', 'Diamonds')
      ]
      implementation.deck.cards = [ Rummy::Card.new('2', 'Clubs') ]
      implementation.discard.cards = [ Rummy::Card.new('K', 'Spades') ]
      game.game_state = implementation
      game.save!
      sign_in_as game.users.first
      visit game_path(game)
      click_on 'Draw from stock'
      check 'hand-card-7-Spades'
      check 'hand-card-7-Hearts'
      check 'hand-card-7-Diamonds'
      click_button 'Meld'
    end

    it 'ends the game once the last card is discarded' do
      check 'hand-card-2-Clubs'

      click_button 'Discard'

      expect(page).to have_content "#{game.users.first.name} wins!"
    end
  end

  describe 'the ranked game-over modal' do
    let!(:game) { create :game, type: 'RummyGame', game_size: 3, player_count: 3 }

    before do
      implementation = game.game_state
      implementation.players[0].hand = [
        Rummy::Card.new('7', 'Spades'), Rummy::Card.new('7', 'Hearts'), Rummy::Card.new('7', 'Diamonds')
      ]
      implementation.players[1].hand = [ Rummy::Card.new('K', 'Spades') ]
      implementation.players[2].hand = [ Rummy::Card.new('2', 'Clubs'), Rummy::Card.new('3', 'Diamonds') ]
      implementation.deck.cards = [ Rummy::Card.new('7', 'Clubs') ]
      implementation.discard.cards = [ Rummy::Card.new('Q', 'Hearts') ]
      game.game_state = implementation
      game.save!
      sign_in_as game.users.first
      visit game_path(game)
      click_on 'Draw from stock'
    end

    it 'shows the winner and the remaining players ranked by ascending pip total' do
      check 'hand-card-7-Spades'
      check 'hand-card-7-Hearts'
      check 'hand-card-7-Diamonds'
      check 'hand-card-7-Clubs'

      click_button 'Meld'

      within '#game-over-modal' do
        expect(page).to have_content "#{game.users.first.name} wins!"
        expect(page).to have_content "2. #{game.users.third.name}"
        expect(page).to have_content '5 pips'
        expect(page).to have_content "3. #{game.users.second.name}"
        expect(page).to have_content '10 pips'
      end
    end
  end

  describe 'selection survives an unrelated board refresh', :js do
    before do
      implementation = game.game_state
      implementation.players.first.hand = [ Rummy::Card.new('2', 'Clubs'), Rummy::Card.new('3', 'Diamonds') ]
      implementation.deck.cards = [ Rummy::Card.new('9', 'Hearts') ]
      implementation.discard.cards = [ Rummy::Card.new('K', 'Spades') ]
      game.game_state = implementation
      game.save!
      sign_in_as game.users.first
      visit game_path(game)
      click_on 'Draw from stock'
      expect(page).to have_selector('.game-board__hand .playing-card', count: 3)
    end

    it 'keeps a checked-but-unsubmitted card checked through a broadcast refresh' do
      check_hand_card 'hand-card-2-Clubs'
      expect(page).to have_field('hand-card-2-Clubs', checked: true)

      game.game_state.players.last.hand = game.game_state.players.last.hand
      game.save!

      expect(page).to have_field('hand-card-2-Clubs', checked: true)
    end
  end

  describe 'clearing hand card selection', :js do
    before do
      implementation = game.game_state
      implementation.players.first.hand = [
        Rummy::Card.new('2', 'Clubs'), Rummy::Card.new('5', 'Diamonds'), Rummy::Card.new('9', 'Hearts')
      ]
      implementation.deck.cards = [ Rummy::Card.new('3', 'Spades') ]
      implementation.discard.cards = [ Rummy::Card.new('K', 'Spades') ]
      game.game_state = implementation
      game.save!
      sign_in_as game.users.first
      visit game_path(game)
      click_on 'Draw from stock'
      expect(page).to have_selector('.game-board__hand .playing-card', count: 4)
    end

    it 'unchecks every checked hand card and disables the action buttons again' do
      check_hand_card 'hand-card-2-Clubs'
      check_hand_card 'hand-card-5-Diamonds'
      expect(page).to have_field('hand-card-2-Clubs', checked: true)

      click_button 'Clear'

      expect(page).to have_field('hand-card-2-Clubs', checked: false)
      expect(page).to have_field('hand-card-5-Diamonds', checked: false)
      expect(page).to have_button('Discard', disabled: true)
    end
  end

  describe 'an invalid meld shows an error toast', :js do
    before do
      implementation = game.game_state
      implementation.players.first.hand = [
        Rummy::Card.new('2', 'Clubs'), Rummy::Card.new('5', 'Diamonds'), Rummy::Card.new('9', 'Hearts')
      ]
      implementation.deck.cards = [ Rummy::Card.new('3', 'Spades') ]
      implementation.discard.cards = [ Rummy::Card.new('K', 'Spades') ]
      game.game_state = implementation
      game.save!
      sign_in_as game.users.first
      visit game_path(game)
      click_on 'Draw from stock'
      expect(page).to have_selector('.game-board__hand .playing-card', count: 4)
    end

    it 'rejects the meld and surfaces a warning toast' do
      check_hand_card 'hand-card-2-Clubs'
      check_hand_card 'hand-card-5-Diamonds'
      check_hand_card 'hand-card-9-Hearts'

      click_button 'Meld'

      expect(page).to have_selector('.alert--warning', text: "That's not a valid meld")

      find('[aria-label="Dismiss error"]').click

      expect(page).not_to have_selector('.alert-banner--active')
    end
  end
end
