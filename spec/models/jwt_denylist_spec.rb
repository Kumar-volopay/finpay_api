require "rails_helper"

RSpec.describe JwtDenylist do
  describe "validations" do
    it "requires a JTI" do
      denylist = build(:jwt_denylist, jti: nil, exp: 1.hour.from_now)
      expect(denylist).not_to be_valid
    end

    it "requires an expiration time" do
      denylist = build(:jwt_denylist, jti: SecureRandom.uuid, exp: nil)
      expect(denylist).not_to be_valid
    end
  end

  describe "table configuration" do
    it "uses the public jwt_denylist table" do
      expect(described_class.table_name).to eq("public.jwt_denylist")
    end
  end
end
