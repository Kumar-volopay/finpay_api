require "rails_helper"

RSpec.describe InvitationPolicy do
  let(:admin) do
    build(:user, role: :admin, id: 1)
  end

  let(:member) do
    build(:user, role: :member, id: 2)
  end

  describe "#create?" do
    it "allows an admin to create an invitation" do
      expect(described_class.new(admin, Invitation).create?).to be true
    end

    it "denies a member from creating an invitation" do
      expect(described_class.new(member, Invitation).create?).to be false
    end

    it "denies an unauthenticated user from creating an invitation" do
      expect(described_class.new(nil, Invitation).create?).to be_nil
    end
  end
end
