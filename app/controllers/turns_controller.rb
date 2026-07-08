class TurnsController < ApplicationController
  def create
    @game = Game.find_by(id: turn_params[:game_id])
    if Turn.new(turn_params)
      @game.play(turn_params[:player], turn_params[:rank], turn_params[:user_id])
      return redirect_to game_path(@game.reload)
    else
    end
    render :show, layout: "application-no-sidebar"
  end

  private

  def turn_params
    params.expect(turn: [ :player, :rank, :game_id, :user_id ])
  end
end
