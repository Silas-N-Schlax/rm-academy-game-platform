require 'rails_helper'
RSpec.describe Leaderboard, type: :model do
  describe '.sorted_by' do
    it 'orders by total wins descending when given "total_wins"' do
      more_wins = create(:user, name: 'More Wins')
      fewer_wins = create(:user, name: 'Fewer Wins')
      create_finished_game(winner: more_wins)
      create_finished_game(winner: more_wins)
      create_finished_game(winner: fewer_wins)

      names = described_class.sorted_by('total_wins').map(&:name)

      expect(names.index('More Wins')).to be < names.index('Fewer Wins')
    end

    it 'defaults to sorting by total wins descending when no column is given' do
      more_wins = create(:user, name: 'More Wins')
      fewer_wins = create(:user, name: 'Fewer Wins')
      create_finished_game(winner: more_wins)
      create_finished_game(winner: more_wins)
      create_finished_game(winner: fewer_wins)

      names = described_class.sorted_by.map(&:name)

      expect(names.index('More Wins')).to be < names.index('Fewer Wins')
    end

    it 'breaks a tie on the sort column alphabetically by name' do
      zed = create(:user, name: 'Zed')
      alice = create(:user, name: 'Alice')
      create_finished_game(winner: zed)
      create_finished_game(winner: alice)

      names = described_class.sorted_by('total_wins').map(&:name)

      expect(names.index('Alice')).to be < names.index('Zed')
    end

    it 'excludes an in-progress game from every column' do
      user = create(:user, name: 'In Progress Player')
      in_progress_game = create(:started_game, player_count: 0)
      create(:player, user:, game: in_progress_game)

      row = described_class.sorted_by.find { |candidate| candidate.name == 'In Progress Player' }

      expect(row.total_games).to eq 0
      expect(row.total_wins).to eq 0
      expect(row.seconds_played).to eq 0
    end

    it 'excludes an archived-but-never-finished game from every column' do
      user = create(:user, name: 'Archived Player')
      archived_game = create(:archived_game, player_count: 0)
      create(:player, user:, game: archived_game)

      row = described_class.sorted_by.find { |candidate| candidate.name == 'Archived Player' }

      expect(row.total_games).to eq 0
      expect(row.total_wins).to eq 0
      expect(row.seconds_played).to eq 0
    end

    it 'includes a user with zero finished games, with a nil win percentage and zero seconds played' do
      user = create(:user, name: 'Never Played')

      row = described_class.sorted_by.find { |candidate| candidate.name == 'Never Played' }

      expect(row).to_not be_nil
      expect(row.win_percentage).to be_nil
      expect(row.seconds_played).to eq 0
    end

    it 'returns one row per user, not one row per game' do
      user = create(:user, name: 'Frequent Player')
      create_finished_game(winner: user)
      create_finished_game(winner: user)
      create_finished_game(winner: user)

      matching_rows = described_class.sorted_by.select { |candidate| candidate.name == 'Frequent Player' }

      expect(matching_rows.size).to eq 1
    end

    it 'issues exactly one SQL query' do
      create(:user)
      query_count = 0
      counter = ->(*, payload) { query_count += 1 if payload[:sql].strip.start_with?(/select/i) }

      ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') { described_class.sorted_by.to_a }

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
