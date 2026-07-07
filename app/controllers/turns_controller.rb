class TurnsController < ApplicationController
  def create
    @turn = Turn.new(turn_params)
  end

  private

  def turn_params
    params.expect(turn: [ :player, :rank, :game_id, :user_id ])
  end
end
