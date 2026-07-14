class Player < ApplicationRecord
  belongs_to :game
  belongs_to :user

  after_create_commit { broadcast_refresh_later_to "games" }
  after_update_commit { broadcast_refresh_later_to "games" }

  validates :game, uniqueness: { scope: :user, message: "You cannot join this game" }
end
