require 'factory_bot_rails'

include FactoryBot::Syntax::Methods


# * Populate with default users
user1 = create :user
user2 = create :user

# * Create some mock games (status: waiting...)
2.times do
  create :game, users: [ user1 ], player_count: 0
  create :game, type: "CrazyEightsGame", users: [ user1 ], player_count: 0
end

# * Create some games with players (status: started...)
2.times do
  create(:started_game, users: [ user1, user2 ], player_count: 0)
  create(:started_game, type: "CrazyEightsGame", users: [ user1, user2 ], player_count: 0)
end


# * Create some games that have finished (status: finished...)
8.times do |i|
  game = create(:finished_game)
  if i.even?
    create(:player_as_winner, user: user1, game:)
    create(:player, user: user2, game:)
  else
    create(:player, user: user1, game:)
    create(:player_as_winner, user: user2, game:)
  end
end
