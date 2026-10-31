
require "rails_helper"
require "digest"

RSpec.describe Authentication::RefreshTokenService do
  let!(:company) do
    Companies::Provision.call(
      name: "Refresh Spec Company",
      subdomain: "refresh_spec_company"
    )
  end

  let!(:other_company) do
    Companies::Provision.call(
      name: "Other Refresh Spec Company",
      subdomain: "other_refresh_spec"
    )
  end

  let!(:user) do
    Apartment::Tenant.switch(company.subdomain) do
      create(:user, email: "refresh_member@example.com")
    end
  end

  let(:raw_token) { "test-refresh-token-123" }
  let(:token_digest) { Digest::SHA256.hexdigest(raw_token) }

  def create_refresh_token(expires_at: 1.day.from_now, revoked_at: nil)
    Apartment::Tenant.switch(company.subdomain) do
      create(
        :refresh_token,
        user: user,
        token_digest: token_digest,
        expires_at: expires_at,
        revoked_at: revoked_at
      )
    end
  end

  describe ".rotate" do
    it "rotates a valid refresh token" do
      create_refresh_token

      result = described_class.rotate(
        raw_token: raw_token,
        company: company
      )

      expect(result).to be_present

      returned_user, new_raw_token = result
      expect(returned_user.id).to eq(user.id)
      expect(new_raw_token).to be_present
      expect(new_raw_token).not_to eq(raw_token)

      old_token = Apartment::Tenant.switch(company.subdomain) do
        RefreshToken.find_by(token_digest: token_digest)
      end
      expect(old_token).to be_revoked
    end

    it "rejects an expired refresh token" do
      create_refresh_token(expires_at: 1.minute.ago)

      result = described_class.rotate(
        raw_token: raw_token,
        company: company
      )

      expect(result).to be_nil
    end

    it "rejects a revoked refresh token" do
      create_refresh_token(revoked_at: Time.current)

      result = described_class.rotate(
        raw_token: raw_token,
        company: company
      )

      expect(result).to be_nil
    end

    it "rejects reuse of a rotated refresh token" do
      create_refresh_token

      first_result = described_class.rotate(
        raw_token: raw_token,
        company: company
      )
      expect(first_result).to be_present

      second_result = described_class.rotate(
        raw_token: raw_token,
        company: company
      )

      expect(second_result).to be_nil
    end

    it "rejects a refresh token used with the wrong company" do
      create_refresh_token

      result = described_class.rotate(
        raw_token: raw_token,
        company: other_company
      )

      expect(result).to be_nil
    end
  end
end
