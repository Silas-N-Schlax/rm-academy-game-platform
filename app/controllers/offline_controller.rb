class OfflineController < ApplicationController
  allow_unauthenticated_access only: %i[ index ]
  def index
    render layout: "application_no_sidebar"
  end
end
