class CreatePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :players do |t|
      t.timestamps
      t.references :user, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true
    end
  end
end
