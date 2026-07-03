class Player < ApplicationRecord
  belongs_to :game
  belongs_to :user

  validates :game, uniqueness: { scope: :user, message: "You cannot join this game" }
end
