require "jwt"

module AuthHelpers
  def auth_headers(user, company)
    token = Authentication::TokenService.encode(
      user: user,
      company_id: company.id
    )

    bearer_headers(token)
  end

  def expired_auth_headers(user, company)
    token = Authentication::TokenService.encode(
      user: user,
      company_id: company.id
    )

    payload = JWT.decode(token, nil, false).first
    payload["exp"] = 1.minute.ago.to_i

    secret = Rails.application.credentials.dig(:jwt, :secret_key)

    bearer_headers(
      JWT.encode(payload, secret, "HS256")
    )
  end

  def revoked_auth_headers(user, company)
    token = Authentication::TokenService.encode(
      user: user,
      company_id: company.id
    )

    payload = JWT.decode(token, nil, false).first

    JwtDenylist.create!(
      jti: payload.fetch("jti"),
      exp: Time.at(payload.fetch("exp"))
    )

    bearer_headers(token)
  end

  def wrong_tenant_auth_headers(user, company)
    auth_headers(user, company)
  end

  private

  def bearer_headers(token)
    { "Authorization" => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
