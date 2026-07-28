class StatsController < ApplicationController
  def index
    @presenter = StatsPresenter.new(Current.session.user)
  end
end
