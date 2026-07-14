class Player < ApplicationRecord
  belongs_to :game
  belongs_to :user

  after_create_commit :update_games_list

  validates :game, uniqueness: { scope: :user, message: "You cannot join this game" }

  private

  def update_games_list
    broadcast_replace_to(
      "games",
      partial: "application/game_card",
      locals: { item: self.game, post: true },
      target: self.game
    )
  end
end
