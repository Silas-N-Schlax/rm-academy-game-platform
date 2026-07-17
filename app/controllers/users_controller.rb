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
      flash.now[:alert] = "Something went wrong"
      render :new, layout: "application_no_sidebar", status: :unprocessable_content
    end
  end

  def update
    @user = User.find(current_user.id)
    if @user.update(update_params)
      return redirect_to users_show_path
    end
    render :edit, status: :unprocessable_content, layout: "modal"
  end

  def turbo_fetch
    @user = User.new(update_params)
  end

  def edit
    @user = User.find(current_user.id)
    render layout: "modal"
  end

  def show
    @user = User.find(current_user.id)
  end

  private

  def update_params
    params.require(:user).permit(:name, :street_address, :country, :state, :city, :zip_code)
  end
end
