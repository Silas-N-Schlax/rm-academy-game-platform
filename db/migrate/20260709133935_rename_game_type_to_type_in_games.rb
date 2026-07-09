class RenameGameTypeToTypeInGames < ActiveRecord::Migration[8.1]
  def change
    rename_column :games, :type, :type
  end
end
