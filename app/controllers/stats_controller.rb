class StatsController < ApplicationController
  def index
    @user = Current.session.user
    @stat = Stat.new
  end
end
