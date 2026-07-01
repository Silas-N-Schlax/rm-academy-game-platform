module SigninHelper
  def log_in_user(user)
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: user.password
    click_button "Sign In"
    sleep 0.3
  end
end
