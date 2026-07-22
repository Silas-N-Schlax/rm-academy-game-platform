class RulesController < ApplicationController
  def index
    @games = GameCatalog.data.all
  end

  def show
    @game = GameCatalog.data.find!(params[:id])
  end
end
