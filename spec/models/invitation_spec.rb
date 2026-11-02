require "rails_helper"

RSpec.describe Invitation, type: :model do
  let(:company) do
    Companies::Provision.call(
      name: "Invitation Spec Company",
      subdomain: "invitation_spec_company"
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
end
