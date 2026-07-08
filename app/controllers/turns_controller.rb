class TurnsController < ApplicationController
  def create
    @game = Game.find_by(id: turn_params[:game_id])
    if Turn.new(turn_params).valid?
      @game.play(turn_params[:player], turn_params[:rank], turn_params[:user_id])
      return redirect_to game_path(@game)
    end
    render_page(@game)
  end

  private

  def render_page(game)
    return redirect_to root_path unless @game.joined?(turn_params[:user_id])
    return redirect_to games_path(@game) if @game.game_state.nil?
    @game = game
    @game_state = @game.game_state
    @user = User.find(turn_params[:user_id])
    render "games/show", layout: "application_no_sidebar", status: :unprocessable_content
  end

  def turn_params
    params.expect(turn: [ :player, :rank, :game_id, :user_id ])
  end
end
