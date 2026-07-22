require 'rails_helper'

RSpec.describe 'Go Fish ask button', type: :system do
  let!(:game) { create :started_game, game_size: 3, player_count: 3 }

  before do
    game.start!
    game.game_state.players.first.hand = [ GoFish::Card.new('7'), GoFish::Card.new('J') ]
    game.save!
    sign_in_as game.users.first
  end

  it 'labels the submit button with the selected player and rank', :js do
    opponents = game.game_state.list_of_players(game.users.first.id)

    visit game_path(game)

    expect(page).to have_button "Ask #{opponents.first.name} for 7s"

    select opponents.last.name, from: 'Player'
    select 'Jack', from: 'Rank'

    expect(page).to have_button "Ask #{opponents.last.name} for Jacks"
  end
end
