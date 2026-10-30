# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Database constraints" do
  describe "Category constraints" do
    it "rejects a null category name" do
      category = build(:category, name: nil)

      expect {
        category.save!(validate: false)
      }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it "rejects duplicate category names" do
      create(:category, name: "Food")
      duplicate = build(:category, name: "Food")

      expect {
        duplicate.save!(validate: false)
      }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  describe "Expense constraints" do
    it "rejects zero amount" do
      expense = build(:expense, amount_cents: 0)

      expect {
        expense.save!(validate: false)
      }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it "rejects invalid currency format" do
      expense = build(:expense, currency: "usd")

      expect {
        expense.save!(validate: false)
      }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it "rejects an invalid user foreign key" do
      expense = build(:expense)
      expense.user_id = -1

      expect {
        expense.save!(validate: false)
      }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it "rejects an invalid category foreign key" do
      expense = build(:expense)
      expense.category_id = -1

      expect {
        expense.save!(validate: false)
      }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  describe "Receipt constraints" do
    it "rejects a null file name" do
      receipt = build(:receipt, file_name: nil)

      expect {
        receipt.save!(validate: false)
      }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it "rejects a null content type" do
      receipt = build(:receipt, content_type: nil)

      expect {
        receipt.save!(validate: false)
      }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it "rejects a null byte size" do
      receipt = build(:receipt, byte_size: nil)

      expect {
        receipt.save!(validate: false)
      }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it "rejects a null storage key" do
      receipt = build(:receipt, storage_key: nil)

      expect {
        receipt.save!(validate: false)
      }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it "rejects an invalid expense foreign key" do
      receipt = build(:receipt)
      receipt.expense_id = -1

      expect {
        receipt.save!(validate: false)
      }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end
end
