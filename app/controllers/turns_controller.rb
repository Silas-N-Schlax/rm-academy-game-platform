class TurnsController < ApplicationController
  def create
    @turn = game_class.turn_class.new(turn_params)
    if @turn.valid_turn?
      return redirect_to game_path(@turn.game)
    end
    render "games/show", layout: "application_no_sidebar", status: :unprocessable_content
  end

  private

  def turn_params
    params.expect(turn: [ :player, :rank ]).merge({ game_id: params[:game_id], user_id: Current.session.user.id })
  end

  def game_class
    Game.find(params[:game_id])
  end
end
