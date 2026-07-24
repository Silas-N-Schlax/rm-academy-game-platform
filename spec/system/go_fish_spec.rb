require 'rails_helper'

RSpec.describe 'Go Fish', type: :system do
  context 'when a Go Fish game has been dealt' do
    let!(:game) { create :game, type: 'GoFishGame', game_size: 3, player_count: 3 }

    before do
      game.start!
      sign_in_as game.users.first
      visit game_path(game.reload)
    end

    it 'renders the dealt hand, stock, and every opponent seat' do
      implementation = game.game_state
      your_player = implementation.find_player(game.users.first.id)
      opponents = implementation.players.reject { |player| player.id == game.users.first.id }

      expect(page).to have_content "Stock: #{implementation.deck.cards_left}"
      expect(page).to have_selector(data_test('hand-card'), count: your_player.hand.size)
      opponents.each { |opponent| expect(page).to have_content opponent.name }
    end

    it 'sends the player back to the home page' do
      find(data_test('board-back-button')).click
      expect(page).to have_current_path root_path
    end

    it "shows counts but no card images on an opponent's seat tile" do
      within all(data_test('opponent-seat')).first do
        expect(page).to_not have_selector 'img.playing-card'
        expect(page).to_not have_selector data_test('opponent-hand-card')
      end
    end
  end

  context 'when it is your turn' do
    let!(:game) { create :game, type: 'GoFishGame', game_size: 2, player_count: 2 }

    before do
      game.start!
      game.game_state.players.first.hand = [ GoFish::Card.new('7', 'Spades') ]
      game.game_state.players.last.hand = [ GoFish::Card.new('7', 'Hearts') ]
      game.save!
      sign_in_as game.users.first
      visit game_path(game.reload)
    end

    def choose_hand_card(card_id)
      find("label[for='#{card_id}']", visible: :all)
      page.execute_script("document.querySelector(\"label[for='#{card_id}']\").click()")
    end

    it 'asks the selected opponent for the selected rank and persists the result', :js do
      opponent = game.game_state.players.last

      choose_hand_card 'hand-card-7-Spades'
      find(data_test('opponent-seat'), text: opponent.name).click

      expect(page).to have_selector(data_test('hand-card'), count: 2)
      game.reload
      expect(game.game_state.players.first.hand.map(&:rank)).to eq [ "7", "7" ]
      expect(game.game_state.players.last.hand.size).to eq 1
    end

    it 'highlights the card when a real user clicks the visible card image', :js do
      find(data_test('hand-card-image')).click

      expect(page).to have_selector(".playing-card--active")
    end

    it 'asks instead of opening the detail modal when a real user clicks a card then an opponent', :js do
      opponent = game.game_state.players.last

      find(data_test('hand-card-image')).click
      find(data_test('opponent-seat'), text: opponent.name).click

      expect(page).to_not have_selector data_test('opponent-detail-modal'), visible: true
      expect(page).to have_selector(data_test('hand-card'), count: 2)
    end

    it 'opens the opponent detail modal with their hand and books when no card is selected', :js do
      opponent = game.game_state.players.last

      find(data_test('opponent-seat'), text: opponent.name).click

      expect(page).to have_selector("#{data_test('opponent-detail-modal')}[open]")
      within data_test('opponent-detail-modal') do
        expect(page).to have_content opponent.name
        expect(page).to have_content 'Hand'
        expect(page).to have_content 'Books'
        expect(page).to have_selector(data_test('opponent-detail-hand-card'), count: 1)
      end

      find(data_test('opponent-detail-close')).click
      expect(page).to_not have_selector("#{data_test('opponent-detail-modal')}[open]")
    end
  end

  context 'when you have completed a book' do
    let!(:game) { create :game, type: 'GoFishGame', game_size: 2, player_count: 2 }

    before do
      game.start!
      game.game_state.players.first.books = [ GoFish::Book.new('K') ]
      game.save!
      sign_in_as game.users.first
      visit game_path(game.reload)
    end

    it 'renders your completed books' do
      expect(page).to have_selector data_test('your-book-card')
    end
  end

  context 'when a turn has been played' do
    let!(:game) { create :game, type: 'GoFishGame', game_size: 2, player_count: 2 }

    before do
      game.start!
      game.game_state.players.first.hand = [ GoFish::Card.new('7', 'Spades') ]
      game.game_state.players.last.hand = [ GoFish::Card.new('7', 'Hearts') ]
      game.save!
      sign_in_as game.users.first
      visit game_path(game.reload)
    end

    def choose_hand_card(card_id)
      find("label[for='#{card_id}']", visible: :all)
      page.execute_script("document.querySelector(\"label[for='#{card_id}']\").click()")
    end

    it 'shows the finished turn in the feed drawer once opened', :js do
      opponent = game.game_state.players.last

      choose_hand_card 'hand-card-7-Spades'
      find(data_test('opponent-seat'), text: opponent.name).click
      expect(page).to have_selector(data_test('hand-card'), count: 2)

      find(data_test('open-feed-button')).click

      within data_test('feed-drawer') do
        expect(page).to have_content 'You'
        expect(page).to have_content "asked #{opponent.name} for any 7s"
      end
    end

    it 'announces what just happened in the action notice', :js do
      opponent = game.game_state.players.last

      choose_hand_card 'hand-card-7-Spades'
      find(data_test('opponent-seat'), text: opponent.name).click
      expect(page).to have_selector(data_test('hand-card'), count: 2)

      expect(page).to have_selector("#{data_test('action-notice')}.action-notice--active")
      within data_test('action-notice') do
        expect(page).to have_content "#{opponent.name} ran out of cards, they drew a card"
      end
    end

    it "shows the opponent's last action on their seat tile", :js do
      opponent = game.game_state.players.last

      choose_hand_card 'hand-card-7-Spades'
      find(data_test('opponent-seat'), text: opponent.name).click
      expect(page).to have_selector(data_test('hand-card'), count: 2)

      within data_test('opponent-seat') do
        expect(page).to have_content 'ran out of cards, they drew a card'
      end
    end
  end

  context 'when the game has ended' do
    let!(:game) { create :game, type: 'GoFishGame', game_size: 2, player_count: 2 }

    before do
      game.start!
      state = game.game_state
      state.deck = []
      state.players.each { |player| player.hand = [] }
      state.players.first.books = [ GoFish::Book.new('K') ]
      game.game_state = state
      game.save!
      sign_in_as game.users.first
      visit game_path(game.reload)
    end

    it 'auto-opens the game-over modal with the winner and ranking', :js do
      expect(page).to have_selector("#{data_test('game-over-modal')}[open]")
      within data_test('game-over-modal') do
        expect(page).to have_content "#{game.game_state.players.first.name} wins!"
        expect(page).to have_content 'Ranked by books, most first'
      end
    end
  end

  context 'when it is not your turn' do
    let!(:game) { create :game, type: 'GoFishGame', game_size: 2, player_count: 2 }

    before do
      game.start!
      sign_in_as game.users.last
      visit game_path(game.reload)
    end

    it 'renders hand cards as disabled' do
      expect(page).to have_selector "#{data_test('hand-card')}[disabled]", minimum: 1
    end
  end
end
