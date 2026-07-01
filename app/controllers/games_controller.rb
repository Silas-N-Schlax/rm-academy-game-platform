class GamesController < ApplicationController
  def history
  end

  def create
    @game = Game.new(user_params)
    if @game.save
      redirect_to "/games/#{@game.id}/show"
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
    @game = Game.find(params[:id])
  end

  def new
    @game = Game.new
  end

  private

  def user_params
    params.require(:game).permit(:name, :game_type, :game_size)
  end
end
