require 'factory_bot_rails'

include FactoryBot::Syntax::Methods

# Bump these to grow the performance-testing dataset.
PLAYER_COUNT = 1000
GAME_COUNT = 1000

GAME_SIZE_RANGES = {
  "GoFishGame" => (2..6),
  "CrazyEightsGame" => (2..7)
}.freeze

def random_game_type
  GAME_SIZE_RANGES.keys.sample
end

def random_finished_timing
  started_at = rand(1..180).days.ago
  { started_at:, finished_at: started_at + rand(1..90).minutes }
end

# Seed passwords are throwaway dev/demo data, not real credentials, so skip
# bcrypt's full cost factor to avoid a multi-minute hashing tax at 1000+ users.
ActiveModel::SecurePassword.min_cost = true

ActiveRecord::Base.transaction do
  puts "Seeding #{PLAYER_COUNT} users..."
  users = create_list(:user, PLAYER_COUNT)

  puts "Seeding #{GAME_COUNT} games..."
  GAME_COUNT.times do |i|
    type = random_game_type
    game_size = rand(GAME_SIZE_RANGES.fetch(type))

    case i % 10
    when 0
      # abandoned lobby that got auto-archived before it ever filled up
      participants = users.sample(rand(1...game_size))
      create(:waiting_game, :archived, :with_players, type:, game_size:, participants:)
    when 1, 2
      # still open, waiting on more players to join
      participants = users.sample(rand(1...game_size))
      create(:waiting_game, :with_players, type:, game_size:, participants:)
    when 3, 4
      # full lobby, in progress
      participants = users.sample(game_size)
      create(:started_game, :with_players, type:, game_size:, participants:)
    else
      # full lobby, finished with a winner
      participants = users.sample(game_size)
      timing = random_finished_timing
      traits = [ :finished_game, :with_players ]
      # games finished more than 2 days ago would have been swept up by ArchiveGameJob
      traits << :archived if timing[:finished_at] < 2.days.ago

      create(*traits, type:, game_size:, participants:, winning_user: participants.sample, **timing)
    end
  end

  puts "Done: #{User.count} users, #{Game.count} games, #{Player.count} players."
  puts "Log in as any seeded user with <email> / password (e.g. #{users.first.email_address} / password)."
end
