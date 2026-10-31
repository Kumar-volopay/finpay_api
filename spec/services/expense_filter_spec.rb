require "rails_helper"

RSpec.describe ExpenseFilter do
  let!(:category) { create(:category) }
  let!(:another_category) { create(:category) }

  let!(:pending_expense) do
    create(
      :expense,
      category: category,
      status: :pending,
      incurred_on: Date.new(2026, 10, 10)
    )
  end

  let!(:approved_expense) do
    create(
      :expense,
      category: category,
      status: :approved,
      incurred_on: Date.new(2026, 10, 15)
    )
  end

  let!(:other_category_expense) do
    create(
      :expense,
      category: another_category,
      status: :rejected,
      incurred_on: Date.new(2026, 10, 20)
    )
  end

  let(:scope) { Expense.all }

  describe "#call" do
    it "returns all expenses when no filters are provided" do
      result = described_class.new(scope, {}).call

      expect(result).to contain_exactly(
        pending_expense,
        approved_expense,
        other_category_expense
      )
    end

    it "filters by category_id" do
      result = described_class.new(
        scope,
        category_id: category.id
      ).call

      expect(result).to contain_exactly(
        pending_expense,
        approved_expense
      )
    end

    it "filters by status" do
      result = described_class.new(
        scope,
        status: "pending"
      ).call

      expect(result).to contain_exactly(pending_expense)
    end

    it "filters by from date" do
      result = described_class.new(
        scope,
        from: "2026-10-15"
      ).call

      expect(result).to contain_exactly(
        approved_expense,
        other_category_expense
      )
    end

    it "filters by to date" do
      result = described_class.new(
        scope,
        to: "2026-10-15"
      ).call

      expect(result).to contain_exactly(
        pending_expense,
        approved_expense
      )
    end

    it "filters by a date range" do
      result = described_class.new(
        scope,
        from: "2026-10-10",
        to: "2026-10-15"
      ).call

      expect(result).to contain_exactly(
        pending_expense,
        approved_expense
      )
    end

    it "combines category and status filters" do
      result = described_class.new(
        scope,
        category_id: category.id,
        status: "approved"
      ).call

      expect(result).to contain_exactly(approved_expense)
    end

    it "rejects an unknown status" do
      expect {
        described_class.new(scope, status: "cancelled").call
      }.to raise_error(ArgumentError, "Invalid expense status")
    end

    it "rejects an invalid date format" do
      expect {
        described_class.new(scope, from: "15-10-2026").call
      }.to raise_error(ArgumentError, "Invalid from date")
    end

    it "rejects an impossible date" do
      expect {
        described_class.new(scope, from: "2026-02-30").call
      }.to raise_error(ArgumentError, "Invalid from date")
    end

    it "rejects unknown filter keys" do
      expect {
        described_class.new(scope, unknown: "value").call
      }.to raise_error(ArgumentError, /Unknown filters/)
    end

    it "rejects a from date later than the to date" do
      expect {
        described_class.new(
          scope,
          from: "2026-10-20",
          to: "2026-10-10"
        ).call
      }.to raise_error(
        ArgumentError,
        "From date cannot be after to date"
      )
    end

    it "rejects an invalid category_id" do
      expect {
        described_class.new(scope, category_id: "abc").call
      }.to raise_error(ArgumentError, "Invalid category_id")
    end
  end
end
