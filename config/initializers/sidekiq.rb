# frozen_string_literal: true

require "sidekiq/web"
require "rack/auth/basic"
require "digest"

redis_url =
  if Rails.env.production?
    ENV.fetch("REDIS_URL")
  else
    ENV.fetch("REDIS_URL", "redis://127.0.0.1:6380/0")
  end

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end

Sidekiq::Web.use ActionDispatch::Cookies
Sidekiq::Web.use ActionDispatch::Session::CookieStore,
                 key: "_finpay_sidekiq",
                 same_site: :strict,
                 secure: Rails.env.production?

Sidekiq::Web.use Rack::Auth::Basic, "FINPAY Sidekiq" do |username, password|
  expected_username = ENV["SIDEKIQ_WEB_USERNAME"]
  expected_password = ENV["SIDEKIQ_WEB_PASSWORD"]

  next false if expected_username.nil? || expected_username.empty?
  next false if expected_password.nil? || expected_password.empty?

  ActiveSupport::SecurityUtils.secure_compare(
    Digest::SHA256.hexdigest(username),
    Digest::SHA256.hexdigest(expected_username)
  ) &&
    ActiveSupport::SecurityUtils.secure_compare(
      Digest::SHA256.hexdigest(password),
      Digest::SHA256.hexdigest(expected_password)
    )
end
