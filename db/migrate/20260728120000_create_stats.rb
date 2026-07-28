class CreateStats < ActiveRecord::Migration[8.1]
  def change
    create_view :stats
  end
end
