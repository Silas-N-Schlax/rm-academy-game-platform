require 'rails_helper'
RSpec.describe 'Games', type: :system do
  let!(:user) { create(:user) }

  context 'when the user goes to the index' do
    let!(:game) { create(:game, game_size: 3, player_count: 1) }
    let!(:game2) { create(:game, player_count: 0) }
    before do
      sign_in_as user
      visit games_path
    end
    it 'shows the games index' do
      expect(page).to have_content 'Your Games'
      expect(page).to have_content 'Open Games'
    end

    it 'shows open games and users games' do
      visit root_path
      expect(page).to have_css('#user-games > *', count: 2)
      expect(page).to have_css('#open-games > *', count: 2)
    end

    context 'when a user clicks on a game they joined', :js do
      before do
        sign_in_as game.users.first
        visit games_path
      end
      it 'shows them the waiting game' do
        expected_content = 'Waiting for the game to start...'
        click_on 'Play'
        expect(page).to have_content expected_content
      end
    end

    context 'when a user clicks on a game they have not joined' do
      before do
        visit root_path
        click_on 'Join'
      end
      it 'shows them that game and joins the game if they can join' do
        expected_player_count = 2
        expect(current_path).to eq game_path(game.id)
        expect(page).to have_content game.name
        expected_content = 'Waiting for the game to start...'
        expect(page).to have_content expected_content
        expect(Player.where(game_id: game.id).size).to eq expected_player_count
      end
    end
  end

  context 'when the user does not have all the content' do
    let(:user) { create :user }
    before do
      sign_in_as user
      visit root_path
    end
    it 'displays "no games" page with create button when no games' do
      expected_content = 'crickets...'
      expect(page).to have_content expected_content
    end

    it 'displays "you have no games" when no games to show' do
      create(:game, player_count: 1)
      game = create(:finished_game)
      sign_in_as game.users.first
      visit root_path
      expected_content = 'You have no active games...'
      expect(page).to have_content expected_content
    end

    it 'displays "no open games available" when no open games to show' do
      game = create :game
      create(:player, game:, user:)
      visit root_path
      expected_content = 'There are no open games to join...'
      expect(page).to have_content expected_content
    end
  end

  context 'when the history page is displayed' do
    let!(:game1) { create :finished_game }
    let!(:game2) { create :finished_game }
    let!(:user) { create :user }
    let!(:player) { create(:player_as_winner, user:, game: game1) }
    before do
      sign_in_as user
      visit history_games_path
    end
    it 'shows history of games' do
      expect(page).to have_content 'History'
      expect(page).to have_css '[data-testid="history-column"]', count: 1
      expect(page).to have_content user.name
    end
  end


  context 'when a users click new game button' do
    before do
      game = create :game
      create(:player, game:, user:)
    end
    it 'shows the new game page' do
      sign_in_as user
      visit games_path
      click_on 'New Game'
      expect(page).to have_selector '#new-game-form'
    end
  end

  context 'when the user creates a new game' do
    it 'creates a new game and sends user to that page' do
      game_name = 'RoleModel'
      sign_in_as user
      visit new_game_path
      expect do
        fill_in_new_game_form(3, game_name)
        expect(page).to have_content game_name
      end.to change(Game, :count).by 1
    end
  end

   context 'when a game has started' do
    let!(:game) { create :game }
    before do
      game.start!
      sign_in_as game.users.first
      visit game_path(game)
    end
    it 'has a timer that auto submits the form when expired', :js, :fast_timer do
      expect(page).to have_selector('.timer')
      expect(page).to have_selector('.game-feed__question')
    end

    it 'displays the countdown as a whole number', :js do
      expect(find('.timer__time').text).to match(/\A\d+\z/)
    end

    it 'does not reset the countdown when the page is reloaded', :js do
      remaining_before_reload = find('.timer')['data-timer-seconds-value'].to_f
      travel 20.seconds do
        visit game_path(game)
        remaining_after_reload = find('.timer')['data-timer-seconds-value'].to_f
        expect(remaining_after_reload).to be_within(1).of(remaining_before_reload - 20)
      end
    end

    context 'when the player gets to go again' do
      let!(:game) { create :game }
      before do
        game.start!
        implementation = game.game_state
        implementation.deck.cards = [ GoFish::Card.new('J') ]
        players = implementation.players
        players.first.hand = [ GoFish::Card.new('J') ]
        players.last.hand = [ GoFish::Card.new('J'), GoFish::Card.new('10') ]
        game.save
        sign_in_as game.users.first
      end
      it 'resets timer', :js, :fast_timer do
        visit game_path(game)
        sleep 3
        expect(page).to have_selector('.game-feed__question', count: 2)
      end
    end

    context 'when the game is over' do
      let!(:game) { create :game }
      before do
        implementation = game.game_state
        implementation.deck.cards = []
        players = implementation.players
        players.first.hand = [ GoFish::Card.new('J'), GoFish::Card.new('J'), GoFish::Card.new('J') ]
        players.last.hand = [ GoFish::Card.new('J') ]
        game.save
      end
      it 'removes timers when game is over', :js do
        visit game_path(game)
        click_on 'Ask'
        expect(page).to_not have_selector('.timer')
      end
    end
  end

  context 'when a user goes a game they have not joined' do
    it 'redirects them to home page' do
      sign_in_as user
      game = create :game
      visit game_path(game.id)
      expect(current_path).to eq root_path
    end
  end

  context 'when the user inputs invalid data' do
    it 're-renders from with errors' do
      game_name = 'G'
      sign_in_as user
      fill_in_new_game_form(7, game_name)
      expect(page).to have_selector '#new-game-form'
      expect(page).to have_content 'is too short'
    end
  end

  context 'when a go fish game has ended' do
    let!(:game) { create :game }
    before do
      sign_in_as game.users.first
      game.start!
      state = game.game_state
      state.deck = []
      state.players.each { |player| player.hand = [] }
      state.players.first.books = [ GoFish::Book.new('K') ]
      game.game_state = state
      game.save!
      visit game_path(game)
    end
    it 'shows the winner banner' do
      expect(page).to have_content 'Game Over'
      expect(page).to have_content "#{game.game_state.players.first.name} won the game!"
    end
  end

  context 'when the user goes offline on a game page', :chrome do
    let!(:game) { create :game }
    before do
      sign_in_as game.users.first
      game.start!
      visit game_path(game)
      wait_for_service_worker_control
      emulate_worker_network(offline: true)
    end
    it 'displays offline banner' do
      expect(page).to have_selector('.offline-banner--active')
      emulate_worker_network(offline: false)
      expect(page).to have_no_selector('.offline-banner--active')
    end
  end

  def fill_in_new_game_form(game_size, game_name)
    visit new_game_path
    fill_in 'Name', with: game_name
    select 'Go Fish Game', from: 'Type'
    fill_in 'Game size', with: game_size
    click_on 'Create Game'
  end
end
