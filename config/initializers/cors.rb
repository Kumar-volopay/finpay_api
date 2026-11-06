# frozen_string_literal: true

allowed_origins =
  if Rails.env.production?
    ENV.fetch("CORS_ALLOWED_ORIGINS").split(",").map(&:strip).reject(&:empty?)
  else
    ENV.fetch("CORS_ALLOWED_ORIGINS", "http://localhost:3000")
       .split(",")
       .map(&:strip)
       .reject(&:empty?)
  end

if allowed_origins.empty? || allowed_origins.include?("*")
  raise "CORS_ALLOWED_ORIGINS must contain explicit origins and cannot use *"
end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins)

    resource "/api/*",
      headers: %w[Authorization Content-Type Accept X-Request-Id],
      methods: %i[get post put patch delete options head],
      max_age: 600
  end
end
