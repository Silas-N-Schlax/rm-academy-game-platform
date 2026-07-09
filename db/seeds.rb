# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
#
#
# Has 1 game
# Has 3 users
# 2 users have joined a game

require 'factory_bot_rails'

include FactoryBot::Syntax::Methods


# * Populate with default users
user1 = create :user
user2 = create :user

# * Create some mock games (status: waiting...)
6.times do
  create :game
end

# * Create some games with players (status: started...)
4.times do
  game = create(:started_game)
  create(:player, user: user1, game:)
  create(:player, user: user2, game:)
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
