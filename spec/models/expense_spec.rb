# frozen_string_literal: true

require "rails_helper"

RSpec.describe Expense do
  subject(:expense) { build(:expense) }

  it "is valid with valid attributes" do
    expect(expense).to be_valid
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
  end

  it "requires an uppercase three-letter currency" do
    expense.currency = "usd"
    expect(expense).not_to be_valid
  end

  it "supports the pending status" do
    expense.status = "pending"
    expect(expense).to be_valid
  end

  it "filters expenses by user" do
    expect(described_class).to respond_to(:for_user)
  end

  it "encrypts notes" do
    expense.notes = "Private notes"

    expect(expense.notes).to eq("Private notes")
    expect(expense.class.encrypted_attributes).to include(:notes)
  end
end
