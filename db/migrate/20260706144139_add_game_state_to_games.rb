class AddGameStateToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :game_state, :jsonb
  end
end
