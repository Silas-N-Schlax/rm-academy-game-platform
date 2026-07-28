require 'rails_helper'
RSpec.describe Leaderboard, type: :model do
  let(:leaderboard) { described_class.new }

  describe '#rows' do
    it 'orders by total wins descending when wins differ' do
      more_wins = create(:user, name: 'More Wins')
      fewer_wins = create(:user, name: 'Fewer Wins')
      create_finished_game(winner: more_wins)
      create_finished_game(winner: more_wins)
      create_finished_game(winner: fewer_wins)

      names = leaderboard.rows.map(&:name)

      expect(names.index('More Wins')).to be < names.index('Fewer Wins')
    end

    it 'breaks a wins tie by total games descending' do
      opponent = create(:user, name: 'Opponent')
      more_games = create(:user, name: 'More Games')
      fewer_games = create(:user, name: 'Fewer Games')
      create_finished_game(winner: more_games, others: [ opponent ])
      create_finished_game(winner: opponent, others: [ more_games ])
      create_finished_game(winner: fewer_games)

      names = leaderboard.rows.map(&:name)

      expect(names.index('More Games')).to be < names.index('Fewer Games')
    end

    it 'breaks a wins-and-games tie by total time played descending' do
      more_time = create(:user, name: 'More Time')
      less_time = create(:user, name: 'Less Time')
      create_finished_game(winner: more_time, started_at: 3.hours.ago, finished_at: Time.current)
      create_finished_game(winner: less_time, started_at: 1.hour.ago, finished_at: Time.current)

      names = leaderboard.rows.map(&:name)

      expect(names.index('More Time')).to be < names.index('Less Time')
    end

    it 'breaks a tie on every other column by account age, older first' do
      older_account = create(:user, name: 'Older Account')
      newer_account = create(:user, name: 'Newer Account')
      shared_start = 1.hour.ago
      shared_finish = Time.current
      create_finished_game(winner: older_account, started_at: shared_start, finished_at: shared_finish)
      create_finished_game(winner: newer_account, started_at: shared_start, finished_at: shared_finish)

      names = leaderboard.rows.map(&:name)

      expect(names.index('Older Account')).to be < names.index('Newer Account')
    end

    it 'excludes an in-progress game from every column' do
      user = create(:user, name: 'In Progress Player')
      in_progress_game = create(:started_game, player_count: 0)
      create(:player, user:, game: in_progress_game)

      row = leaderboard.rows.find { |candidate| candidate.name == 'In Progress Player' }

      expect(row.total_games).to eq 0
      expect(row.total_wins).to eq 0
      expect(row.seconds_played).to eq 0
    end

    it 'excludes an archived-but-never-finished game from every column' do
      user = create(:user, name: 'Archived Player')
      archived_game = create(:archived_game, player_count: 0)
      create(:player, user:, game: archived_game)

      row = leaderboard.rows.find { |candidate| candidate.name == 'Archived Player' }

      expect(row.total_games).to eq 0
      expect(row.total_wins).to eq 0
      expect(row.seconds_played).to eq 0
    end

    it 'includes a user with zero finished games, with a nil win percentage and zero seconds played' do
      user = create(:user, name: 'Never Played')

      row = leaderboard.rows.find { |candidate| candidate.name == 'Never Played' }

      expect(row).to_not be_nil
      expect(row.win_percentage).to be_nil
      expect(row.seconds_played).to eq 0
    end

    it 'returns one row per user, not one row per game' do
      user = create(:user, name: 'Frequent Player')
      create_finished_game(winner: user)
      create_finished_game(winner: user)
      create_finished_game(winner: user)

      matching_rows = leaderboard.rows.select { |candidate| candidate.name == 'Frequent Player' }

      expect(matching_rows.size).to eq 1
    end

    it 'issues exactly one SQL query' do
      create(:user)
      query_count = 0
      counter = ->(*, payload) { query_count += 1 if payload[:sql].strip.start_with?(/select/i) }

      ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') { leaderboard.rows.to_a }

      expect(query_count).to eq 1
    end
  end
end

def create_finished_game(winner:, others: [], started_at: 1.hour.ago, finished_at: Time.current)
  game = create(:game, player_count: 0, started_at:, finished_at:)
  create(:player_as_winner, user: winner, game:)
  others.each { |opponent| create(:player, user: opponent, game:) }
  game
end
