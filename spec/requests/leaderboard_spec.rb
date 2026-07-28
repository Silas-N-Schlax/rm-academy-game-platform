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

  describe 'sorting by win percentage' do
    it 'places a user with no win percentage last when sorted descending' do
      winner = create(:user, name: 'Has A Win')
      finish_a_game_won_by(winner)
      never_played = create(:user, name: 'Never Played')

      get leaderboard_index_path, params: { q: { s: 'win_percentage desc' } }

      expect(response.body.index('Has A Win')).to be < response.body.index('Never Played')
    end

    it 'places a user with no win percentage last when sorted ascending' do
      winner = create(:user, name: 'Has A Win')
      finish_a_game_won_by(winner)
      never_played = create(:user, name: 'Never Played')

      get leaderboard_index_path, params: { q: { s: 'win_percentage asc' } }

      expect(response.body.index('Has A Win')).to be < response.body.index('Never Played')
    end
  end

  it 'returns 200 instead of erroring when a range value is non-numeric' do
    get leaderboard_index_path, params: { q: { total_wins_gteq: 'not-a-number' } }

    expect(response).to have_http_status(:ok)
  end

  it 'returns 200 and ignores an unpermitted ransack attribute' do
    get leaderboard_index_path, params: { q: { created_at_cont: 'ignored' } }

    expect(response).to have_http_status(:ok)
  end

  describe 'filtering by name' do
    it 'includes a player whose name contains the search term' do
      player = create(:user, name: 'Searchable Player')

      get leaderboard_index_path, params: { q: { name_cont: 'Searchable' } }

      expect(response.body).to include('Searchable Player')
    end

    it 'excludes a player whose name does not contain the search term' do
      create(:user, name: 'Unrelated Player')

      get leaderboard_index_path, params: { q: { name_cont: 'Searchable' } }

      expect(response.body).to_not include('Unrelated Player')
    end
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
