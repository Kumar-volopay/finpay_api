require "rails_helper"

RSpec.describe ExpensePolicy do
  let(:admin) { build(:user, role: :admin, id: 1) }
  let(:member) { build(:user, role: :member, id: 2) }
  let(:another_member) { build(:user, role: :member, id: 3) }

  let(:own_expense) do
    build(:expense, user: member, status: :pending)
  end

  let(:another_expense) do
    build(:expense, user: another_member, status: :pending)
  end

  describe "#index?" do
    it "allows an admin" do
      expect(described_class.new(admin, Expense).index?).to be true
    end

    it "allows a member" do
      expect(described_class.new(member, Expense).index?).to be true
    end

    it "denies an unauthenticated user" do
      expect(described_class.new(nil, Expense).index?).to be false
    end
  end

  describe "#show?" do
    it "allows a member to view their own expense" do
      expect(described_class.new(member, own_expense).show?).to be true
    end

    it "denies a member access to another member's expense" do
      expect(described_class.new(member, another_expense).show?).to be false
    end

    it "allows an admin to view another member's expense" do
      expect(described_class.new(admin, another_expense).show?).to be true
    end
  end

  describe "#create?" do
    it "allows an authenticated member" do
      expect(described_class.new(member, Expense).create?).to be true
    end

    it "denies an unauthenticated user" do
      expect(described_class.new(nil, Expense).create?).to be false
    end
  end

  describe "#update?" do
    it "allows a member to update their own pending expense" do
      expect(described_class.new(member, own_expense).update?).to be true
    end

    it "denies a member updating another member's expense" do
      expect(described_class.new(member, another_expense).update?).to be false
    end

    it "denies updating an approved expense" do
      expense = build(:expense, user: member, status: :approved)

      expect(described_class.new(member, expense).update?).to be false
    end

    it "allows an admin to update another member's pending expense" do
      expect(described_class.new(admin, another_expense).update?).to be true
    end
  end

  describe "#destroy?" do
    it "allows a member to delete their own pending expense" do
      expect(described_class.new(member, own_expense).destroy?).to be true
    end

    it "denies a member deleting another member's expense" do
      expect(described_class.new(member, another_expense).destroy?).to be false
    end

    it "denies deleting a rejected expense" do
      expense = build(:expense, user: member, status: :rejected)

      expect(described_class.new(member, expense).destroy?).to be false
    end

    it "allows an admin to delete another member's pending expense" do
      expect(described_class.new(admin, another_expense).destroy?).to be true
    end
  end

  describe "Scope#resolve" do
    it "returns all expenses for an admin within the current tenant" do
      scope = double("Expense scope")

      expect(scope).to receive(:all)

      described_class::Scope.new(admin, scope).resolve
    end

    it "returns only the current member's expenses" do
      scope = double("Expense scope")

      expect(scope).to receive(:where).with(user_id: member.id)

      described_class::Scope.new(member, scope).resolve
    end

    it "returns no expenses for an unauthenticated user" do
      scope = Expense.all

      expect(described_class::Scope.new(nil, scope).resolve).to be_empty
    end
  end
end
