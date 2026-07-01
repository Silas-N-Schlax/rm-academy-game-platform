class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.string :name, null: false
      t.string :game_type, null: false
      t.integer :game_size, null: false
      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps
    end
  end
end
