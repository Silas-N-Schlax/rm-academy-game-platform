class GamesController < ApplicationController
  def new
    @game = Game.new
  end

  def index
    @game = Game.new
    @user = current_user
  end

  def create
    @game = Game.new(user_params)
    @user = current_user
    if @game.save
      @game.players.create(user_id: @user.id)
      redirect_to game_path(@game.id)
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
    @game = Game.find(params[:id])
    @user = current_user
    @game_state = @game.start!
    unless @game.joined?(@user.id)
      redirect_to root_path
    end
    render layout: "application_no_sidebar"
  end

  def join
    @game = Game.find(params[:id])
    @user = current_user
    if @game.open_spots? && @game.players.create(user_id: @user.id)
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

  def current_user
    Current.session.user
  end

  def user_params
    params.require(:game).permit(:name, :game_type, :game_size)
  end
end
