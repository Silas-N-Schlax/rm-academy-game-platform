class TurnsController < ApplicationController
  def create
    @turn = Turn.new(turn_params.merge({ game_id: params[:game_id], user_id: Current.session.user.id }))
    if @turn.valid_turn?
      return redirect_to game_path(@turn.game)
    end
    render "games/show", layout: "application_no_sidebar", status: :unprocessable_content
  end

  private

  def turn_params
    params.expect(turn: [ :player, :rank ])
  end
end
