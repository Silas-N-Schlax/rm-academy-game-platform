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

    it 'breaks a tie on a non-default sort column alphabetically by name' do
      zed = create(:user, name: 'Zed')
      alice = create(:user, name: 'Alice')
      create_finished_game(winner: zed)
      create_finished_game(winner: alice)

      names = described_class.sorted_by('total_games').map(&:name)

      expect(names.index('Alice')).to be < names.index('Zed')
    end

    it 'breaks a name tie on a non-default sort column by created_at ascending' do
      older = create(:user, name: 'Same Name', created_at: 2.days.ago)
      newer = create(:user, name: 'Same Name', created_at: 1.day.ago)
      create_finished_game(winner: older)
      create_finished_game(winner: newer)

      ids_in_order = described_class.sorted_by('total_games').map(&:id)

      expect(ids_in_order.index(older.id)).to be < ids_in_order.index(newer.id)
    end

    it 'sorts by the full universal rank chain, not just name, when sorting by the default "total_wins" column' do
      started_at = 1.hour.ago
      finished_at = Time.current
      older = create(:user, name: 'Zed', created_at: 2.days.ago)
      newer = create(:user, name: 'Alice', created_at: 1.day.ago)
      create_finished_game(winner: older, started_at:, finished_at:)
      create_finished_game(winner: newer, started_at:, finished_at:)

      names = described_class.sorted_by('total_wins').map(&:name)

      expect(names.index('Zed')).to be < names.index('Alice')
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

    it 'reaches the country through the user association' do
      user = create(:user, name: 'From Wakanda', country: 'WK')

      row = described_class.sorted_by.find { |candidate| candidate.name == 'From Wakanda' }

      expect(row.user.country).to eq 'WK'
    end

    it 'nils out win_percentage for a user with fewer than 5 finished games, even with all wins' do
      user = create(:user, name: 'Undefeated Newcomer')
      4.times { create_finished_game(winner: user) }

      row = described_class.sorted_by.find { |candidate| candidate.name == 'Undefeated Newcomer' }

      expect(row.win_percentage).to be_nil
    end

    it 'computes a real win_percentage once a user has played exactly 5 finished games' do
      user = create(:user, name: 'Seasoned Player')
      5.times { create_finished_game(winner: user) }

      row = described_class.sorted_by.find { |candidate| candidate.name == 'Seasoned Player' }

      expect(row.win_percentage).to eq 100.0
    end

    it 'returns one row per user, not one row per game' do
      user = create(:user, name: 'Frequent Player')
      create_finished_game(winner: user)
      create_finished_game(winner: user)
      create_finished_game(winner: user)

      matching_rows = described_class.sorted_by.select { |candidate| candidate.name == 'Frequent Player' }

      expect(matching_rows.size).to eq 1
    end

    it 'sorts a user with no win percentage after users with a win percentage, when sorted by win_percentage' do
      never_played = create(:user, name: 'Never Played')
      has_a_win = create(:user, name: 'Has A Win')
      create_finished_game(winner: has_a_win)

      names = described_class.sorted_by('win_percentage').map(&:name)

      expect(names.index('Has A Win')).to be < names.index('Never Played')
    end

    it 'returns nil for an unrecognized sort column' do
      expect(described_class.sorted_by('name')).to be_nil
    end

    it 'orders by total wins ascending, without the universal tiebreak chain, when direction is "asc"' do
      more_wins = create(:user, name: 'More Wins')
      fewer_wins = create(:user, name: 'Fewer Wins')
      create_finished_game(winner: more_wins)
      create_finished_game(winner: more_wins)
      create_finished_game(winner: fewer_wins)

      names = described_class.sorted_by('total_wins', direction: 'asc').map(&:name)

      expect(names.index('Fewer Wins')).to be < names.index('More Wins')
    end

    it 'orders a non-default column ascending when direction is "asc"' do
      more_games = create(:user, name: 'More Games')
      fewer_games = create(:user, name: 'Fewer Games')
      create_finished_game(winner: more_games, others: [ fewer_games ])
      create_finished_game(winner: more_games)

      names = described_class.sorted_by('total_games', direction: 'asc').map(&:name)

      expect(names.index('Fewer Games')).to be < names.index('More Games')
    end

    it 'still breaks a tie by name/created_at when sorting a non-default column ascending' do
      zed = create(:user, name: 'Zed')
      alice = create(:user, name: 'Alice')
      create_finished_game(winner: zed)
      create_finished_game(winner: alice)

      names = described_class.sorted_by('total_games', direction: 'asc').map(&:name)

      expect(names.index('Alice')).to be < names.index('Zed')
    end

    it 'falls back to descending for an unrecognized direction' do
      more_wins = create(:user, name: 'More Wins')
      fewer_wins = create(:user, name: 'Fewer Wins')
      create_finished_game(winner: more_wins)
      create_finished_game(winner: more_wins)
      create_finished_game(winner: fewer_wins)

      names = described_class.sorted_by('total_wins', direction: 'sideways').map(&:name)

      expect(names.index('More Wins')).to be < names.index('Fewer Wins')
    end

    it 'only applies the universal tiebreak chain to total_wins descending, not total_wins ascending' do
      started_at = 1.hour.ago
      finished_at = Time.current
      older = create(:user, name: 'Zed', created_at: 2.days.ago)
      newer = create(:user, name: 'Alice', created_at: 1.day.ago)
      create_finished_game(winner: older, started_at:, finished_at:)
      create_finished_game(winner: newer, started_at:, finished_at:)

      names = described_class.sorted_by('total_wins', direction: 'asc').map(&:name)

      expect(names.index('Alice')).to be < names.index('Zed')
    end

    it 'breaks a full tie on every stat column by created_at ascending, older account ranking higher' do
      older = create(:user, name: 'Older Account', created_at: 2.days.ago)
      newer = create(:user, name: 'Newer Account', created_at: 1.day.ago)

      rows = described_class.sorted_by.index_by(&:name)

      expect(rows['Older Account'].rank).to be < rows['Newer Account'].rank
    end

    it 'never assigns the same rank to two different users' do
      create_list(:user, 3, created_at: 1.day.ago)

      ranks = described_class.sorted_by.map(&:rank)

      expect(ranks.uniq.size).to eq ranks.size
    end

    it 'assigns consecutive ranks starting at 1 with no gaps' do
      create_list(:user, 3)

      ranks = described_class.sorted_by.map(&:rank).sort

      expect(ranks).to eq (1..3).to_a
    end

    it "keeps a user's rank the same no matter which column the results are sorted by" do
      top_scorer = create(:user, name: 'Top Scorer')
      create_finished_game(winner: top_scorer)

      rank_when_sorted_by_wins = described_class.sorted_by('total_wins').find { |row| row.name == 'Top Scorer' }.rank
      rank_when_sorted_by_games = described_class.sorted_by('total_games').find { |row| row.name == 'Top Scorer' }.rank

      expect(rank_when_sorted_by_wins).to eq rank_when_sorted_by_games
    end

    it 'issues exactly one SQL query' do
      create(:user)
      query_count = 0
      counter = ->(*, payload) { query_count += 1 if payload[:sql].strip.start_with?(/select/i) }

      ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') { described_class.sorted_by.to_a }

      expect(query_count).to eq 1
    end
  end

  describe '.stat_bounds' do
    it 'returns the min and max of the given stat across all users' do
      low = create(:user, name: 'Low')
      high = create(:user, name: 'High')
      create_finished_game(winner: high, others: [ low ])
      create_finished_game(winner: high)

      expect(described_class.stat_bounds(:total_wins)).to eq(0..2)
    end

    it 'returns 0..0 when there are no users' do
      expect(described_class.stat_bounds(:total_wins)).to eq(0..0)
    end
  end

  describe '.clamp_per_page' do
    it 'clamps a value below the minimum up to 10' do
      expect(described_class.clamp_per_page(1)).to eq 10
    end

    it 'clamps a value above the maximum down to 100' do
      expect(described_class.clamp_per_page(500)).to eq 100
    end

    it 'leaves an in-range value unchanged' do
      expect(described_class.clamp_per_page(39)).to eq 39
    end

    it 'defaults to 50 when given a blank value' do
      expect(described_class.clamp_per_page(nil)).to eq 50
    end
  end
end

def create_finished_game(winner:, others: [], started_at: 1.hour.ago, finished_at: Time.current)
  game = create(:game, player_count: 0, started_at:, finished_at:)
  create(:player_as_winner, user: winner, game:)
  others.each { |opponent| create(:player, user: opponent, game:) }
  game
end
