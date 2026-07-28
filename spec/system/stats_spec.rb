require 'rails_helper'
RSpec.describe 'Stats', type: :system do
  let!(:user) { create(:user) }
  let!(:opponent) { create(:user) }

  before { sign_in_as user }

  def create_finished_game(type:, winner:, others: [], started_at: 1.hour.ago, finished_at: Time.current)
    game = create(:game, type:, player_count: 0, started_at:, finished_at:)
    create(:player_as_winner, user: winner, game:)
    others.each { |opponent| create(:player, user: opponent, game:) }
    game
  end

  it 'shows the stats page' do
    visit stats_path

    expect(page).to have_content 'Stats'
    expect(current_path).to eq stats_path
  end

  it 'shows overall totals across every game type' do
    create_finished_game(type: 'GoFishGame', winner: user, others: [ opponent ])
    create_finished_game(type: 'CrazyEightsGame', winner: opponent, others: [ user ])

    visit stats_path

    within data_test('stats-ledger-row-overall') do
      expect(find(data_test('total-games')).text).to eq '2'
      expect(find(data_test('total-wins')).text).to eq '1'
      expect(find(data_test('total-losses')).text).to eq '1'
      expect(find(data_test('win-percentage')).text).to eq '50.0%'
    end
  end

  it 'shows a row for every known game type, even one the user has never played' do
    create_finished_game(type: 'GoFishGame', winner: user, others: [ opponent ])

    visit stats_path

    within data_test('stats-ledger-row-crazyeightsgame') do
      expect(find(data_test('total-games')).text).to eq '—'
      expect(find(data_test('total-wins')).text).to eq '—'
    end
  end

  it "shows a game type's totals only for games of that type" do
    create_finished_game(type: 'GoFishGame', winner: user, others: [ opponent ])
    create_finished_game(type: 'CrazyEightsGame', winner: opponent, others: [ user ])

    visit stats_path

    within data_test('stats-ledger-row-gofishgame') do
      expect(find(data_test('total-games')).text).to eq '1'
      expect(find(data_test('total-wins')).text).to eq '1'
    end
  end

  it 'redirects a signed-out visitor' do
    sign_out

    visit stats_path

    expect(current_path).to eq new_session_path
  end
end
