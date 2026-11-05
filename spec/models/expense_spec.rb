# frozen_string_literal: true

require "rails_helper"

RSpec.describe Expense do
  subject(:expense) { build(:expense) }

  it "is valid with valid attributes" do
    expect(expense).to be_valid
  end

  it "belongs to a user" do
    expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
  end

  it "belongs to a category" do
    expect(described_class.reflect_on_association(:category).macro).to eq(:belongs_to)
  end

  it "has many receipts" do
    expect(described_class.reflect_on_association(:receipts).macro).to eq(:has_many)
  end

  it "requires a title" do
    expense.title = nil
    expect(expense).not_to be_valid
  end

  it "requires a positive integer amount" do
    expense.amount_cents = 0
    expect(expense).not_to be_valid

    expense.amount_cents = -100
    expect(expense).not_to be_valid

    expense.amount_cents = 100.5
    expect(expense).not_to be_valid
  end

  it "requires an uppercase three-letter currency" do
    expense.currency = "usd"
    expect(expense).not_to be_valid
  end

  it "requires an incurred date" do
    expense.incurred_on = nil
    expect(expense).not_to be_valid
  end

  it "supports the pending status" do
    expense.status = "pending"
    expect(expense).to be_valid
  end

  it "rejects an invalid status" do
    expense.status = "invalid"

    expect(expense).not_to be_valid
    expect(expense.errors[:status]).to be_present
  end

  it "filters expenses by user" do
    user = create(:user)
    another_user = create(:user)
    category = create(:category)

    user_expense = create(:expense, user: user, category: category)
    create(:expense, user: another_user, category: category)

    expect(described_class.for_user(user.id)).to contain_exactly(user_expense)
  end

  it "formats the amount as a decimal string" do
    expense.amount_cents = 1234
    expense.currency = "USD"

    expect(expense.amount_decimal).to eq("12.34")
  end

  it "encrypts notes in the database" do
    expense = create(:expense, notes: "Private notes")

    stored_value = Expense.connection.select_value(
      "SELECT notes FROM expenses WHERE id = #{Expense.connection.quote(expense.id)}"
    )

    expect(stored_value).not_to eq("Private notes")
    expect(expense.reload.notes).to eq("Private notes")
  end

  describe "AASM workflow transitions" do
    it "starts in the pending state" do
      expect(expense).to be_pending
      expect(expense.pending?).to be(true)
    end

    it "transitions from pending to approved" do
      expense.approve!
      expect(expense).to be_approved
    end

    it "transitions from pending to rejected" do
      expense.reject!
      expect(expense).to be_rejected
    end

    it "transitions from approved to reimbursed" do
      expense.status = :approved
      expense.reimburse!
      expect(expense).to be_reimbursed
    end

    it "transitions from reimbursed to archived" do
      expense.status = :reimbursed
      expense.archive!
      expect(expense).to be_archived
    end

    it "does not approve an already approved expense" do
      expense.status = :approved
      expect { expense.approve! }.to raise_error(AASM::InvalidTransition)
    end

    it "does not reimburse a pending expense" do
      expect { expense.reimburse! }.to raise_error(AASM::InvalidTransition)
    end

    it "does not archive a rejected expense" do
      expense.status = :rejected
      expect { expense.archive! }.to raise_error(AASM::InvalidTransition)
    end
  end

  it "creates exactly one activity log when an expense is created directly" do
    expense = build(:expense)

    expect {
      expense.save!
    }.to change(ActivityLog, :count).by(1)

    log = ActivityLog.find_by!(expense: expense)
    expect(log.action).to eq("create")
    expect(log.from_state).to eq("new")
    expect(log.to_state).to eq("pending")
    expect(log.actor).to eq(expense.user)
  end
end
