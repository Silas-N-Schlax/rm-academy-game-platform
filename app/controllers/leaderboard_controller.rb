class LeaderboardController < ApplicationController
  def index
    @rows = Stat.new.leaderboard
    render locals: { your_rank: @rows.index { |row| row.id == current_user.id } + 1 }
  end
end
