require "rails_helper"

RSpec.describe UserPolicy do
  let(:admin) do
    build(:user, role: :admin, id: 1)
  end

  let(:member) do
    build(:user, role: :member, id: 2)
  end

  let(:another_member) do
    build(:user, role: :member, id: 3)
  end

  describe "#show?" do
    it "allows a member to view their own record" do
      expect(described_class.new(member, member).show?).to be true
    end

    it "denies a member access to another member's record" do
      expect(described_class.new(member, another_member).show?).to be false
    end

    it "allows an admin to view another user's record" do
      expect(described_class.new(admin, another_member).show?).to be true
    end
  end

  describe "Scope#resolve" do
    it "returns only the current member's record" do
      scope = double("User scope")
      expect(scope).to receive(:where).with(id: member.id)
      described_class::Scope.new(member, scope).resolve
    end

    it "denies all records to an unauthenticated user" do
      scope = User.all
      expect(described_class::Scope.new(nil, scope).resolve).to be_empty
    end
  end
end
