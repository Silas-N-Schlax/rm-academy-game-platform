RSpec.shared_context "authentication helpers" do
  def sign_in_as(user)
    Current.session = user.sessions.create!

    request = ActionDispatch::Request.new(Rails.application.env_config)
    cookies = request.cookie_jar
    cookies.signed[:session_id] = { value: Current.session.id, httponly: true, same_site: :lax }
  end

  def sign_out
    Current.session&.destroy!
    cookies.delete(:session_id)
  end
end

RSpec.configure { |config| config.include_context "authentication helpers" }

RSpec.configure do |config|
  config.after do
    Rails.application.env_config.delete("action_dispatch.cookies")
    Rails.application.env_config.delete("rack.request.cookie_hash")
  end
end
