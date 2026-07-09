class GamesController < ApplicationController
  def new
    @game = Game.new
  end

  def index
    @game = Game.new
    @user = current_user
  end

  def create
    @game = Game.new(game_params)
    if @game.save_new_game(current_user.id)
      return redirect_to game_path(@game.id)
    end
    render :new, status: :unprocessable_content
  end

  def show
    @turn = Turn.new(game_id: params[:id])
    @turn.game.start!
    return redirect_to root_path unless @turn.game.joined?(current_user.id)
    render layout: "application_no_sidebar"
  end

  def join
    @game = Game.find(params[:id])
    if @game.open_spots? && @game.players.create(user_id: current_user.id)
      redirect_to game_path(@game.id)
    else
      redirect_to root_path
    end
  end

  def history
    @games = Game.all
    @user = current_user
  end

  private

  def game_params
    params.require(:game).permit(:name, :game_type, :game_size)
  end
end
