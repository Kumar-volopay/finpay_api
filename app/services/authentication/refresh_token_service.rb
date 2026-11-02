require "securerandom"
require "digest"

module Authentication
  class RefreshTokenService
    TOKEN_TTL = 7.days

    def self.issue(user:, family_id: SecureRandom.uuid)
      raw_token = SecureRandom.urlsafe_base64(48)

      user.refresh_tokens.create!(
        token_digest: Digest::SHA256.hexdigest(raw_token),
        expires_at: TOKEN_TTL.from_now,
        family_id: family_id
      )

      raw_token
    end

    def self.rotate(raw_token:, company:)
      digest = Digest::SHA256.hexdigest(raw_token)

      Apartment::Tenant.switch(company.subdomain) do
        RefreshToken.transaction do
          refresh_token = RefreshToken.lock.find_by(token_digest: digest)
          next nil unless refresh_token

          if refresh_token.revoked?
            RefreshToken.revoke_family!(refresh_token.family_id)
            next nil
          end

          next nil if refresh_token.expired?

          user = refresh_token.user
          family_id = refresh_token.family_id

          if user.disabled?
            RefreshToken.revoke_family!(family_id)
            next nil
          end

          refresh_token.revoke!

          new_raw_token = issue(
            user: user,
            family_id: family_id
          )

          [ user, new_raw_token ]
        end
      end
    end
  end
end
