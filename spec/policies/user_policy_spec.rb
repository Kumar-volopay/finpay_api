require "rails_helper"

RSpec.describe UserPolicy do
  let(:admin) { build(:user, role: :admin, id: 1) }
  let(:member) { build(:user, role: :member, id: 2) }
  let(:another_member) { build(:user, role: :member, id: 3) }

  describe "#index?" do
    it { expect(described_class.new(admin, User).index?).to be true }
    it { expect(described_class.new(member, User).index?).to be false }
    it { expect(described_class.new(nil, User).index?).to be_nil }
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

    it "denies an unauthenticated user" do
      expect(described_class.new(nil, another_member).show?).to be false
    end
  end

  describe "#create?" do
    it { expect(described_class.new(admin, User).create?).to be true }
    it { expect(described_class.new(member, User).create?).to be false }
    it { expect(described_class.new(nil, User).create?).to be_nil }
  end

  describe "#update?" do
    it "allows an admin to update another user" do
      expect(described_class.new(admin, another_member).update?).to be true
    end

    it "allows a member to update their own record" do
      expect(described_class.new(member, member).update?).to be true
    end

    it "denies a member from updating another user's record" do
      expect(described_class.new(member, another_member).update?).to be false
    end
  end

  describe "#destroy?" do
    it { expect(described_class.new(admin, another_member).destroy?).to be true }
    it { expect(described_class.new(member, another_member).destroy?).to be false }
    it { expect(described_class.new(nil, another_member).destroy?).to be_nil }
  end

  describe "Scope#resolve" do
    it "returns all records for an admin" do
      scope = double("User scope")
      expect(scope).to receive(:all).and_return(:all_users)

      result = described_class::Scope.new(admin, scope).resolve
      expect(result).to eq(:all_users)
    end

    it "returns only the current member's record" do
      scope = double("User scope")
      expect(scope).to receive(:where).with(id: member.id)

      described_class::Scope.new(member, scope).resolve
    end

    it "returns no records for an unauthenticated user" do
      scope = User.all
      expect(described_class::Scope.new(nil, scope).resolve).to be_empty
    end
  end
end
