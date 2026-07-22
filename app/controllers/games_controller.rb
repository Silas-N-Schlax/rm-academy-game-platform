class GamesController < ApplicationController
  before_action :set_game, only: :show
  before_action :require_membership, only: :show

  def new
    @game = Game.new
    render layout: "modal"
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
    render :new, status: :unprocessable_content, layout: "modal"
  end

  def show
    @game.start!
    render layout: "application_no_sidebar"
  end

  def history
    @games = Game.all
    @user = current_user
  end

  private

  def game_params
    params.require(:game).permit(:name, :type, :game_size)
  end

  def set_game
    @game = Game.find(params[:id])
  end

  def require_membership
    redirect_to root_path unless @game.joined?(current_user.id)
  end
end
