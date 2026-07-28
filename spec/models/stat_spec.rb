require 'rails_helper'
RSpec.describe Stat, type: :model do
  describe '.for' do
    let!(:user) { create(:user) }
    let!(:opponent) { create(:user) }

    def create_finished_game(type:, winner:, others: [], started_at: 1.hour.ago, finished_at: Time.current)
      game = create(:game, type:, player_count: 0, started_at:, finished_at:)
      create(:player_as_winner, user: winner, game:)
      others.each { |opponent| create(:player, user: opponent, game:) }
      game
    end

    it 'returns one row per game type, plus one overall row' do
      create_finished_game(type: 'GoFishGame', winner: user, others: [ opponent ])
      create_finished_game(type: 'CrazyEightsGame', winner: user, others: [ opponent ])

      types = described_class.for(user).map(&:type)

      expect(types).to contain_exactly('GoFishGame', 'CrazyEightsGame', nil)
    end

    it 'counts total games and total wins per game type' do
      create_finished_game(type: 'GoFishGame', winner: user, others: [ opponent ])
      create_finished_game(type: 'GoFishGame', winner: opponent, others: [ user ])

      row = described_class.for(user).find { |candidate| candidate.type == 'GoFishGame' }

      expect(row.total_games).to eq 2
      expect(row.total_wins).to eq 1
    end

    it 'sums total games and total wins across all game types for the overall row' do
      create_finished_game(type: 'GoFishGame', winner: user, others: [ opponent ])
      create_finished_game(type: 'CrazyEightsGame', winner: user, others: [ opponent ])

      row = described_class.for(user).find { |candidate| candidate.type.nil? }

      expect(row.total_games).to eq 2
      expect(row.total_wins).to eq 2
    end

    it 'does not count a game that has not finished' do
      unfinished_game = create(:started_game, player_count: 0)
      create(:player, user:, game: unfinished_game)

      expect(described_class.for(user)).to be_empty
    end

    it 'does not count an archived-but-never-finished game' do
      archived_game = create(:archived_game, player_count: 0)
      create(:player, user:, game: archived_game)

      expect(described_class.for(user)).to be_empty
    end

    it 'sums seconds played across finished games' do
      create_finished_game(type: 'GoFishGame', winner: user, others: [ opponent ],
                            started_at: 1.hour.ago, finished_at: Time.current)

      row = described_class.for(user).find { |candidate| candidate.type == 'GoFishGame' }

      expect(row.seconds_played.to_i).to eq 1.hour.to_i
    end

    it 'returns no rows at all for a user with no finished games' do
      expect(described_class.for(user)).to be_empty
    end

    it 'reports the earliest started_at as first_played_at' do
      earlier_game = create_finished_game(type: 'GoFishGame', winner: user, others: [ opponent ],
                                           started_at: 2.days.ago, finished_at: 1.day.ago)
      create_finished_game(type: 'GoFishGame', winner: user, others: [ opponent ],
                            started_at: 1.hour.ago, finished_at: Time.current)

      row = described_class.for(user).find { |candidate| candidate.type == 'GoFishGame' }

      expect(row.first_played_at).to be_within(1.second).of earlier_game.started_at
    end

    it 'does not return a row for a game type the user has never played' do
      row = described_class.for(user).find { |candidate| candidate.type == 'GoFishGame' }

      expect(row).to be_nil
    end

    it 'issues exactly one SQL query' do
      query_count = 0
      counter = ->(*, payload) { query_count += 1 if payload[:sql].strip.start_with?(/select/i) }

      ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') { described_class.for(user).to_a }

      expect(query_count).to eq 1
    end
  end
end
