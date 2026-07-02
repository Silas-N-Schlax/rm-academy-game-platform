class GamesController < ApplicationController
  def new
    @game = Game.new
  end

  def index
    @games = Game.all.to_a
    @user = find_user
  end

  def create
    @game = Game.new(user_params)
    @user = find_user
    if @game.save
      @game.players.create!(user_id: @user.id, game_id: @game.id)
      redirect_to game_path(@game.id)
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
    @game = Game.find(params[:id])
    @user = User.find(Current.session.user_id)
    unless @game.joined?(@user.id)
      redirect_to root_path
    end
  end

  def join
    @game = Game.find(params[:id])
    @user = User.find(Current.session.user_id)
    if @game.can_join?(@user.id)
      @game.players.create!(user_id: @user.id, game_id: @game.id)
      redirect_to game_path(@game)
    else
      redirect_to root_path
    end
  end

  def history
  end

  private

  def find_user
    User.find(Current.session.user_id)
  end

  def user_params
    params.require(:game).permit(:name, :game_type, :game_size)
  end
end
