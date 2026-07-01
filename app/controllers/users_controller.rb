class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
    @user = User.new
    render layout: "application_no_sidebar"
  end

  def create
    @user = User.new(params.require(:user).permit(:email_address, :password, :name, :confirm_password))
    if @user.save
      start_new_session_for @user
      redirect_to root_path
    else
      # redirect_to new_user_path, alert: "There was a problem signing up..."
      flash.now[:alert] = "Something went wrong"
      render :new, layout: "application_no_sidebar", status: :unprocessable_content
    end
  end

  def show
    @user = User.new
  end
end
