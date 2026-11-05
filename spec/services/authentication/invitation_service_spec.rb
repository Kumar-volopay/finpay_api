require "rails_helper"
require "digest"

RSpec.describe Authentication::InvitationService do
  let!(:company) do
    provision_test_tenant(
      name: "Invitation Service Spec Company",
      prefix: "invitation_service"
    )
  end

  let!(:user) do
    Apartment::Tenant.switch(company.subdomain) do
      create(:user)
    end
  end

  describe ".create" do
    it "generates a secure raw invitation token" do
      invitation, raw_token = Apartment::Tenant.switch(company.subdomain) do
        described_class.create(user: user, email: "new@example.com")
      end

      expect(raw_token).to be_present
      expect(raw_token.length).to be >= 32
      expect(invitation).to be_persisted
    end

    it "stores the SHA-256 digest instead of the raw token" do
      invitation, raw_token = Apartment::Tenant.switch(company.subdomain) do
        described_class.create(user: user, email: "digest@example.com")
      end

      expect(invitation.token_digest).to eq(Digest::SHA256.hexdigest(raw_token))
      expect(invitation.token_digest).not_to eq(raw_token)
    end

    it "sets the invitation expiry to 24 hours" do
      before_creation = Time.current

      invitation, = Apartment::Tenant.switch(company.subdomain) do
        described_class.create(user: user, email: "expiry@example.com")
      end

      expected_expiry = before_creation + 24.hours

      expect(invitation.expires_at).to be_within(2.seconds).of(expected_expiry)
    end

    it "uses the member role by default" do
      invitation, = Apartment::Tenant.switch(company.subdomain) do
        described_class.create(user: user, email: "member@example.com")
      end

      expect(invitation.role).to eq(User.roles[:member])
    end
  end

  describe ".find_valid" do
    let(:raw_token) { SecureRandom.urlsafe_base64(32) }

    let!(:invitation) do
      Apartment::Tenant.switch(company.subdomain) do
        create(
          :invitation,
          invited_by: user,
          token_digest: Digest::SHA256.hexdigest(raw_token)
        )
      end
    end

    it "returns an invitation for a valid raw token" do
      result = Apartment::Tenant.switch(company.subdomain) do
        described_class.find_valid(raw_token)
      end

      expect(result).to eq(invitation)
    end

    it "returns nil for a blank token" do
      result = Apartment::Tenant.switch(company.subdomain) do
        described_class.find_valid("")
      end

      expect(result).to be_nil
    end

    it "returns nil for an unknown token" do
      result = Apartment::Tenant.switch(company.subdomain) do
        described_class.find_valid("unknown-token")
      end

      expect(result).to be_nil
    end

    it "returns nil for an expired invitation" do
      Apartment::Tenant.switch(company.subdomain) do
        invitation.update!(expires_at: 1.minute.ago)

        expect(described_class.find_valid(raw_token)).to be_nil
      end
    end

    it "returns nil for an already accepted invitation" do
      Apartment::Tenant.switch(company.subdomain) do
        invitation.update!(accepted_at: Time.current)

        expect(described_class.find_valid(raw_token)).to be_nil
      end
    end
  end
end
