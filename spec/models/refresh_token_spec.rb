require "rails_helper"

RSpec.describe RefreshToken do
  describe "validations" do
    it "requires a token digest" do
      token = build(:refresh_token, token_digest: nil)
      expect(token).not_to be_valid
    end

    it "requires an expiration time" do
      token = build(:refresh_token, expires_at: nil)
      expect(token).not_to be_valid
    end
  end

  describe "#expired?" do
    it "returns true when the token has expired" do
      token = build(:refresh_token, expires_at: 1.minute.ago)
      expect(token.expired?).to be true
    end

    it "returns false when the token has not expired" do
      token = build(:refresh_token, expires_at: 1.hour.from_now)
      expect(token.expired?).to be false
    end
  end

  describe "#revoked?" do
    it "returns true when revoked_at is present" do
      token = build(:refresh_token, revoked_at: Time.current)
      expect(token.revoked?).to be true
    end

    it "returns false when revoked_at is nil" do
      token = build(:refresh_token, revoked_at: nil)
      expect(token.revoked?).to be false
    end
  end
end
