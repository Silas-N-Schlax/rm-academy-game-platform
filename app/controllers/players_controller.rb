class PlayersController < ApplicationController
  def create
    game = Game.find(params[:game_id])
    if game.join(current_user.id)
      redirect_to game_path(game)
    else
      redirect_to root_path
    end
  end
end
