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

      JWT.encode(payload, jwt_secret, "HS256")
    end

    def self.decode(token)
      JWT.decode(
        token,
        jwt_secret,
        true,
        algorithm: "HS256"
      ).first
    end

    def self.jwt_secret
      Rails.application.credentials.dig(:jwt, :secret_key).presence ||
        raise("JWT secret is missing from Rails credentials")
    end

    private_class_method :jwt_secret
  end
end
