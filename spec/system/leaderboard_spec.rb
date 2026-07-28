require 'rails_helper'

RSpec.describe 'Leaderboard', type: :system do
  let!(:top_player) { create(:user, name: 'Top Player') }
  let!(:runner_up) { create(:user, name: 'Runner Up') }
  let!(:viewer) { create(:user, name: 'Viewer') }

  before do
    first_finished_game = create(:finished_game, player_count: 0)
    create(:player_as_winner, user: top_player, game: first_finished_game)
    create(:player, user: runner_up, game: first_finished_game)

    second_finished_game = create(:finished_game, player_count: 0)
    create(:player_as_winner, user: top_player, game: second_finished_game)
    create(:player, user: viewer, game: second_finished_game)

    sign_in_as viewer
  end

  it 'shows every player ranked by total wins' do
    visit leaderboard_index_path

    names_in_order = page.all('.leaderboard__player-name').map(&:text)
    expect(names_in_order).to eq [ 'Top Player', 'Runner Up', 'Viewer' ]
  end

  it 'shows total games, total wins and win/loss ratio for each row' do
    visit leaderboard_index_path

    cells = find('.leaderboard__row', text: 'Top Player').all('td').map(&:text)

    expect(cells[2..4]).to eq [ '2', '2', '100.0%' ]
  end

  it 'shows a formatted time played for each row' do
    visit leaderboard_index_path

    time_played = find('.leaderboard__row', text: 'Top Player').all('td').map(&:text).last
    expected_format = /\A\d{2,}:\d{2}:\d{2}\z/

    expect(time_played).to match expected_format
  end

  it "highlights the signed-in user's own row" do
    visit leaderboard_index_path

    expect(page).to have_css('.leaderboard__row--you', text: 'Viewer')
  end

  it 'marks the top three rows with podium classes' do
    visit leaderboard_index_path

    expect(page).to have_css('.leaderboard__row--first', text: 'Top Player')
    expect(page).to have_css('.leaderboard__row--second', text: 'Runner Up')
    expect(page).to have_css('.leaderboard__row--third', text: 'Viewer')
  end

  it "shows the viewer's rank among all players" do
    visit leaderboard_index_path

    expected_output = "You're #3 of 3 players"
    expect(find('.leaderboard-standing').text.squish).to eq expected_output
  end

  it 'shows a dash in every stat column for a user with no finished games' do
    create(:user, name: 'Never Played')

    visit leaderboard_index_path

    cells = find('.leaderboard__row', text: 'Never Played').all('td').map(&:text)
    expect(cells[2..5]).to eq [ '—', '—', '—', '—' ]
  end

  it 'shows a dash for wins and ratio when a player has played but never won' do
    loser = create(:user, name: 'Always Loses')
    game = create(:finished_game, player_count: 0)
    create(:player_as_winner, user: top_player, game:)
    create(:player, user: loser, game:)

    visit leaderboard_index_path

    cells = find('.leaderboard__row', text: 'Always Loses').all('td').map(&:text)
    expect(cells[2..4]).to eq [ '1', '—', '—' ]
  end

  it 'shows a sort control with an option for each stat, defaulting to total wins' do
    visit leaderboard_index_path

    expect(page).to have_field('Games')
    expect(page).to have_field('Won')
    expect(page).to have_field('W/L')
    expect(page).to have_field('Time Played')
    expect(page).to have_checked_field('Won')
  end

  it 'resorts the table by total games when "Games" is chosen' do
    visit leaderboard_index_path

    choose 'Games'

    names_in_order = page.all('.leaderboard__player-name').map(&:text)
    expect(names_in_order).to eq [ 'Top Player', 'Runner Up', 'Viewer' ]
  end

  it 'keeps the chosen sort option selected after resorting' do
    visit leaderboard_index_path

    choose 'Games'

    expect(page).to have_checked_field('Games')
  end

  it "shows the same rank for a player regardless of which sort option is chosen" do
    visit leaderboard_index_path
    rank_sorted_by_wins = find('.leaderboard__row', text: 'Top Player').find('.leaderboard__rank').text

    choose 'Games'

    rank_sorted_by_games = find('.leaderboard__row', text: 'Top Player').find('.leaderboard__rank').text
    expect(rank_sorted_by_games).to eq rank_sorted_by_wins
  end

  it 'shows 50 rows per page by default when more than 50 users exist' do
    create_list(:user, 60)

    visit leaderboard_index_path

    expect(page).to have_css('.leaderboard__row', count: 50)
  end

  it 'shows a page-size selector with options 10, 25, 50, and 100, defaulting to 50' do
    visit leaderboard_index_path

    expect(page).to have_field('10')
    expect(page).to have_field('25')
    expect(page).to have_field('50')
    expect(page).to have_field('100')
    expect(page).to have_checked_field('50')
  end

  it 'shows fewer rows when a smaller page size is chosen', :js do
    create_list(:user, 20)

    visit leaderboard_index_path
    choose '10'

    expect(page).to have_css('.leaderboard__row', count: 10)
  end

  it 'resets to page 1 when the sort option is changed while on a later page', :js do
    create_list(:user, 60)

    visit leaderboard_index_path(page: 2)
    expect(page).to_not have_content('Top Player')

    choose 'Games'

    expect(page).to have_content('Top Player')
  end

  it 'resets to page 1 when the page size is changed while on a later page', :js do
    create_list(:user, 60)

    visit leaderboard_index_path(page: 2)
    expect(page).to_not have_content('Top Player')

    choose '10'

    expect(page).to have_content('Top Player')
  end

  it 'shows a link to the first page but no link to the last page, when on a later page' do
    create_list(:user, 60)

    visit leaderboard_index_path(page: 2)

    expect(page).to have_css(data_test('pagination-first-page'))
    expect(page).to_not have_css(data_test('pagination-last-page'))
  end

  it "shows \"You're #N of X players\" reflecting the total player count, not just the current page" do
    create_list(:user, 60)

    visit leaderboard_index_path

    expect(find('.leaderboard-standing').text).to include('of 63 players')
  end

  it 'redirects a signed-out visitor' do
    sign_out

    visit leaderboard_index_path

    expect(current_path).to eq new_session_path
  end

  context 'on a phone-width viewport', :js do
    it 'shows an icon trigger for each stat column instead of the word label' do
      resize_page(390, 844) do
        visit leaderboard_index_path

        expect(page).to have_css('.leaderboard__head-icon', count: 4, visible: :visible)
        expect(page).to_not have_css('.leaderboard__head-label', visible: :visible)
      end
    end

    it 'positions every stat tooltip below the trigger, not above' do
      resize_page(390, 844) do
        visit leaderboard_index_path

        triggers = page.all('.leaderboard__head-trigger', visible: :visible)
        expect(triggers.size).to eq 4
        triggers.each { |trigger| expect(trigger['data-tooltip-position']).to eq 'bottom' }
      end
    end

    it 'does not let the mobile navbar cover the last row when scrolled to the bottom' do
      create_list(:user, 20)

      resize_page(390, 844) do
        visit leaderboard_index_path
        page.execute_script(<<~JS)
          document.querySelector('.op-page__main').scrollTo(0, document.querySelector('.op-page__main').scrollHeight)
        JS

        last_row_bottom = page.evaluate_script("document.querySelector('.leaderboard__row:last-child').getBoundingClientRect().bottom")
        navbar_top = page.evaluate_script("document.querySelector('.op-page-sidebar--mobile').getBoundingClientRect().top")

        expect(last_row_bottom).to be <= navbar_top
      end
    end

    it 'reveals a tooltip when a stat trigger is focused' do
      resize_page(390, 844) do
        visit leaderboard_index_path

        games_trigger = find('.leaderboard__head-trigger', visible: :visible, match: :first)
        games_trigger.send_keys(:space)

        expect(games_trigger.matches_css?(':focus-visible')).to be true

        opacity_script = "getComputedStyle(document.activeElement, '::before').opacity"
        wait_until { page.evaluate_script(opacity_script) == '1' }

        expect(page.evaluate_script(opacity_script)).to eq '1'
      end
    end
  end
end
