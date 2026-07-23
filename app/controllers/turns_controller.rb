class TurnsController < ApplicationController
  def create
    @game = Game.find(params[:game_id])
    turn = @game.turn_class.new(turn_params)
    if turn.save
      return redirect_to game_path(@game)
    end
    render "games/show", layout: "application_no_sidebar", status: :unprocessable_content, locals: { turn: turn }
  end

  private

  def turn_params
    params.expect(turn: [ :player, :rank, :suit, :request, :wild_suit, :action, :source, :meld_index, card_ids: [] ])
      .merge({ game: @game, user: Current.session.user })
  end
end
