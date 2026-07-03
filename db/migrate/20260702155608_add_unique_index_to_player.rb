class AddUniqueIndexToPlayer < ActiveRecord::Migration[8.1]
  def change
    add_index :players, [ :user_id, :game_id ], unique: true
  end
end
