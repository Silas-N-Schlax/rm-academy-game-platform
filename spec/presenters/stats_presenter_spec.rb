require 'rails_helper'

RSpec.describe StatsPresenter do
  let!(:user) { create(:user) }
  let!(:opponent) { create(:user) }

  def create_finished_game(type:, winner:, others: [], started_at: 1.hour.ago, finished_at: Time.current)
    game = create(:game, type:, player_count: 0, started_at:, finished_at:)
    create(:player_as_winner, user: winner, game:)
    others.each { |opponent| create(:player, user: opponent, game:) }
    game
  end

  describe '#overall' do
    it 'sums totals across every game type' do
      create_finished_game(type: 'GoFishGame', winner: user, others: [ opponent ])
      create_finished_game(type: 'CrazyEightsGame', winner: opponent, others: [ user ])

      overall = described_class.new(user).overall

      expect(overall.total_games).to eq 2
      expect(overall.total_wins).to eq 1
      expect(overall.total_losses).to eq 1
      expect(overall.win_percentage).to eq 50.0
    end

    it 'returns zeroed totals and a nil win percentage for a user with no games' do
      overall = described_class.new(user).overall

      expect(overall.total_games).to eq 0
      expect(overall.win_percentage).to eq 0.0
      expect(overall.first_played_at).to be_nil
    end
  end

  describe '#cards' do
    it 'returns one card per known game type, in Game.valid_types order' do
      cards = described_class.new(user).cards

      expect(cards.map(&:title)).to eq Game.new.valid_types.map { |type| type.underscore.titleize.sub(/\s*Game\z/, '') }
    end

    it 'zeroes out a card for a game type the user has never played' do
      create_finished_game(type: 'GoFishGame', winner: user, others: [ opponent ])

      card = described_class.new(user).cards.find { |candidate| candidate.title == 'Crazy Eights' }

      expect(card.total_games).to eq 0
      expect(card.win_percentage).to eq 0.0
    end

    it "only counts a game type's own games toward its card" do
      create_finished_game(type: 'GoFishGame', winner: user, others: [ opponent ])
      create_finished_game(type: 'CrazyEightsGame', winner: opponent, others: [ user ])

      card = described_class.new(user).cards.find { |candidate| candidate.title == 'Go Fish' }

      expect(card.total_games).to eq 1
      expect(card.total_wins).to eq 1
    end

    it 'computes an average game duration from seconds played over total games' do
      create_finished_game(type: 'GoFishGame', winner: user, others: [ opponent ],
                            started_at: 2.hours.ago, finished_at: 1.hour.ago)
      create_finished_game(type: 'GoFishGame', winner: user, others: [ opponent ],
                            started_at: 1.hour.ago, finished_at: Time.current)

      card = described_class.new(user).cards.find { |candidate| candidate.title == 'Go Fish' }

      expect(card.average_game_duration).to be_within(1).of 1.hour
    end
  end
end
