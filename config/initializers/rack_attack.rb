
# frozen_string_literal: true

require "json"
require "rack/attack"

redis_url =
  if Rails.env.production?
    ENV.fetch("REDIS_URL")
  else
    ENV.fetch("REDIS_URL", "redis://127.0.0.1:6380/0")
  end

# Use an isolated in-memory store for tests.
# Development and production use Redis.
Rack::Attack.cache.store =
  if Rails.env.test?
    ActiveSupport::Cache::MemoryStore.new
  else
    ActiveSupport::Cache::RedisCacheStore.new(
      url: redis_url,
      namespace: "finpay:rack_attack"
    )
  end

LOGIN_PATH = "/api/v1/auth/login"

# Extract and normalize the login email.
login_email = lambda do |request|
  params =
    if request.media_type == "application/json"
      body = request.body.read
      request.body.rewind
      JSON.parse(body)
    else
      request.POST
    end

  params["email"].to_s.strip.downcase.presence
rescue JSON::ParserError
  nil
end

# Login: maximum 5 requests per minute per IP.
Rack::Attack.throttle(
  "login/ip",
  limit: 5,
  period: 1.minute
) do |request|
  request.ip if request.post? && request.path == LOGIN_PATH
end

# Login: maximum 5 requests per minute per normalized email.
Rack::Attack.throttle(
  "login/email",
  limit: 5,
  period: 1.minute
) do |request|
  if request.post? && request.path == LOGIN_PATH
    login_email.call(request)
  end
end

# Authenticated API: maximum 300 requests per minute per user and tenant.
Rack::Attack.throttle(
  "api/authenticated_user",
  limit: 300,
  period: 1.minute
) do |request|
  next unless request.path.start_with?("/api/v1/")
  next if request.path == LOGIN_PATH

  authorization = request.get_header("HTTP_AUTHORIZATION").to_s
  scheme, token = authorization.split(" ", 2)

  next unless scheme == "Bearer" && token.present?

  begin
    payload = Authentication::TokenService.decode(token)

    company_id = payload["company_id"]
    user_id = payload["sub"]

    "#{company_id}:#{user_id}" if company_id.present? && user_id.present?
  rescue JWT::DecodeError, KeyError
    nil
  end
end

# Return the project's standard API error format with Retry-After.
Rack::Attack.throttled_responder = lambda do |request|
  match_data = request.env["rack.attack.match_data"]

  retry_after = [
    match_data[:epoch_time] + match_data[:period] - Time.now.to_i,
    1
  ].max

  request_id =
    request.env["action_dispatch.request_id"] ||
    request.env["HTTP_X_REQUEST_ID"] ||
    SecureRandom.uuid

  body = {
    error: {
      code: "rate_limit_exceeded",
      message: "Too many requests. Please try again later.",
      details: [],
      request_id: request_id
    }
  }

  [
    429,
    {
      "Content-Type" => "application/json; charset=utf-8",
      "Retry-After" => retry_after.to_s,
      "Cache-Control" => "no-store"
    },
    [ JSON.generate(body) ]
  ]
end
