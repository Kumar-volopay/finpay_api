require "rails_helper"

RSpec.describe User do
  describe "validations" do
    it "requires an email" do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
    end

    it "generates a JTI automatically" do
      user = build(:user, jti: nil)
      expect(user).to be_valid
      expect(user.jti).to be_present
    end
  end

  describe "roles" do
    it "supports admin and member roles" do
      expect(build(:user, role: :admin)).to be_admin
      expect(build(:user, role: :member)).to be_member
    end
  end

  describe "refresh tokens association" do
    it "has a refresh_tokens association" do
      association = described_class.reflect_on_association(:refresh_tokens)
      expect(association.macro).to eq(:has_many)
    end
  end
end
