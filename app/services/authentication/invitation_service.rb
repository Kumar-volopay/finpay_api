module Authentication
  class InvitationService
    EXPIRY_PERIOD = 24.hours

    def self.create(user:, email:, role: User.roles[:member])
      raw_token = SecureRandom.urlsafe_base64(32)

      invitation = Invitation.create!(
        email: email,
        token_digest: Digest::SHA256.hexdigest(raw_token),
        role: role,
        invited_by: user,
        expires_at: EXPIRY_PERIOD.from_now
      )

      [ invitation, raw_token ]
    end

    def self.find_valid(raw_token)
      return if raw_token.blank?

      digest = Digest::SHA256.hexdigest(raw_token)
      invitation = Invitation.find_by(token_digest: digest)

      invitation if invitation&.usable?
    end
  end
end
