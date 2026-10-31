require "jwt"
require "securerandom"

module Authentication
  class TokenService
    ACCESS_TOKEN_TTL = 15.minutes.to_i

    def self.encode(user:, company_id:)
      now = Time.current.to_i

      payload = {
        sub: user.id,
        jti: SecureRandom.uuid,
        company_id: company_id,
        iat: now,
        exp: now + ACCESS_TOKEN_TTL
      }

      JWT.encode(
        payload,
        Rails.application.secret_key_base,
        "HS256"
      )
    end

    def self.decode(token)
      JWT.decode(
        token,
        Rails.application.secret_key_base,
        true,
        algorithm: "HS256"
      ).first
    end
  end
end
