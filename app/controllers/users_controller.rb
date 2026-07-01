class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
    render layout: "application_no_sidebar"
  end

  def create
    user = User.new(params.permit(:email_address, :password, :name, :confirm_password))
    if user.save
      start_new_session_for user
      redirect_to root_path
    else
      redirect_to new_user_path, alert: "There was a problem signing up..."
    end
  end

  def show
  end
end
