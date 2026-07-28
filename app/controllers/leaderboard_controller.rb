class LeaderboardController < ApplicationController
  DEFAULT_SORT = "total_wins desc"

  def index
    per_page = Leaderboard.clamp_per_page(params[:per_page])
    search = Leaderboard.ransack(search_params)
    @rows = search.result.page(params[:page]).per(per_page)
    render locals: render_locals(search, per_page)
  end

  private

  def render_locals(search, per_page)
    {
      search: search,
      your_rank: Leaderboard.find_by(id: current_user.id)&.rank,
      per_page: per_page,
      wins_bounds: Leaderboard.stat_bounds(:total_wins),
      games_bounds: Leaderboard.stat_bounds(:total_games)
    }
  end

  def search_params
    (params[:q]&.to_unsafe_h || {}).reverse_merge("s" => DEFAULT_SORT)
  end
end
