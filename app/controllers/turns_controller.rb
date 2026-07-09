class TurnsController < ApplicationController
  def create
    @game = Game.find(params[:game_id])
    turn = @game.turn_class.new(turn_params)
    if turn.save
      return redirect_to game_path(@game)
    end
    render "games/show", layout: "application_no_sidebar", status: :unprocessable_content
  end

  private

  def turn_params
    params.expect(turn: [ :player, :rank ]).merge({ game_id: params[:game_id], user_id: Current.session.user.id })
  end
end
