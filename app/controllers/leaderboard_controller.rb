class LeaderboardController < ApplicationController
  def index
    per_page = Leaderboard.clamp_per_page(params[:per_page])
    @rows = (Leaderboard.sorted_by(params[:sort]) || Leaderboard.sorted_by).page(params[:page]).per(per_page)
    render locals: { your_rank: Leaderboard.find_by(id: current_user.id)&.rank, sort: params[:sort], per_page: per_page }
  end
end
