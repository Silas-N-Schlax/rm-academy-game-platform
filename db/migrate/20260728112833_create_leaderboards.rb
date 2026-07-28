class CreateLeaderboards < ActiveRecord::Migration[8.1]
  def change
    create_view :leaderboards
  end
end
