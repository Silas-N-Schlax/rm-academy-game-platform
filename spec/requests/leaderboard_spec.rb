require 'rails_helper'

RSpec.describe 'Leaderboard', type: :request do
  before { sign_in_as create(:user) }

  describe 'filtering by games won range' do
    it 'includes a player whose win count falls within the range' do
      player = create(:user, name: 'In Range')
      finish_a_game_won_by(player)

      get leaderboard_index_path, params: { q: { total_wins_gteq: 1, total_wins_lteq: 5 } }

      expect(response.body).to include('In Range')
    end

    it 'excludes a player whose win count falls outside the range' do
      player = create(:user, name: 'Out Of Range')
      finish_a_game_won_by(player)

      get leaderboard_index_path, params: { q: { total_wins_gteq: 5, total_wins_lteq: 10 } }

      expect(response.body).to_not include('Out Of Range')
    end
  end

  describe 'filtering by games played range' do
    it 'includes a player whose game count falls within the range' do
      player = create(:user, name: 'Played In Range')
      finish_a_game_won_by(player)

      get leaderboard_index_path, params: { q: { total_games_gteq: 1, total_games_lteq: 5 } }

      expect(response.body).to include('Played In Range')
    end

    it 'excludes a player whose game count falls outside the range' do
      player = create(:user, name: 'Played Out Of Range')
      finish_a_game_won_by(player)

      get leaderboard_index_path, params: { q: { total_games_gteq: 5, total_games_lteq: 10 } }

      expect(response.body).to_not include('Played Out Of Range')
    end
  end

  it 'returns 200 instead of erroring when a range value is non-numeric' do
    get leaderboard_index_path, params: { q: { total_wins_gteq: 'not-a-number' } }

    expect(response).to have_http_status(:ok)
  end

  it 'returns 200 and ignores an unpermitted ransack attribute' do
    get leaderboard_index_path, params: { q: { name_cont: 'ignored' } }

    expect(response).to have_http_status(:ok)
  end

  it 'falls back to the default sort instead of erroring when the sort column is unrecognized' do
    get leaderboard_index_path, params: { q: { s: 'zzzzz asc' } }

    expect(response).to have_http_status(:ok)
  end
end

def finish_a_game_won_by(winner)
  game = create(:game, player_count: 0, started_at: 1.hour.ago, finished_at: Time.current)
  create(:player_as_winner, user: winner, game:)
  game
end
