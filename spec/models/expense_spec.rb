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

  it "encrypts notes" do
    expense.notes = "Private notes"

    expect(expense.notes).to eq("Private notes")
    expect(described_class.encrypted_attributes).to include(:notes)
  end
end
