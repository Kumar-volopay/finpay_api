require "rails_helper"

RSpec.describe Invitation, type: :model do
  let(:company) do
    provision_test_tenant(
      name: "Invitation Spec Company",
      prefix: "invitation_spec"
    )
  end

  let(:user) do
    Apartment::Tenant.switch(company.subdomain) do
      create(:user)
    end
  end

  let(:invitation) do
    Apartment::Tenant.switch(company.subdomain) do
      create(:invitation, invited_by: user)
    end
  end

  before do
    company
  end

  it "normalizes the email address" do
    Apartment::Tenant.switch(company.subdomain) do
      invitation = build(
        :invitation,
        invited_by: user,
        email: "  TEST@EXAMPLE.COM  "
      )

      invitation.valid?

      expect(invitation.email).to eq("test@example.com")
    end
  end

  it "identifies an expired invitation" do
    Apartment::Tenant.switch(company.subdomain) do
      invitation = build(
        :invitation,
        invited_by: user,
        expires_at: 1.minute.ago
      )

      expect(invitation).to be_expired
      expect(invitation).not_to be_usable
    end
  end

  it "rejects an already accepted invitation" do
    Apartment::Tenant.switch(company.subdomain) do
      invitation = build(
        :invitation,
        invited_by: user,
        accepted_at: Time.current
      )

      expect(invitation).not_to be_usable
    end
  end

  it "identifies a valid invitation as usable" do
    expect(invitation).to be_usable
    expect(invitation).not_to be_expired
  end

  describe "validations" do
    it "requires an email address" do
      record = build(:invitation, invited_by: user, email: nil)

      expect(record).not_to be_valid
      expect(record.errors[:email]).to be_present
    end

    it "requires a valid email format" do
      record = build(:invitation, invited_by: user, email: "invalid-email")

      expect(record).not_to be_valid
      expect(record.errors[:email]).to be_present
    end

    it "requires a token digest" do
      record = build(:invitation, invited_by: user, token_digest: nil)

      expect(record).not_to be_valid
      expect(record.errors[:token_digest]).to be_present
    end

  it "requires a unique token digest" do
    Apartment::Tenant.switch(company.subdomain) do
      existing = create(:invitation, invited_by: user)

      duplicate = build(
        :invitation,
        invited_by: user,
        token_digest: existing.token_digest
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:token_digest]).to be_present
    end
  end

    it "requires an expiry date" do
      record = build(:invitation, invited_by: user, expires_at: nil)

      expect(record).not_to be_valid
      expect(record.errors[:expires_at]).to be_present
    end

    it "accepts only supported roles" do
      record = build(:invitation, invited_by: user, role: 2)

      expect(record).not_to be_valid
      expect(record.errors[:role]).to be_present
    end
  end
end
