# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExpensePresenter do
  describe "#amount" do
    it "formats USD amounts with two decimal places" do
      expense = build(:expense, amount_cents: 1234, currency: "USD")

      expect(described_class.new(expense).amount).to eq("12.34")
    end

    it "formats JPY amounts without decimal places" do
      expense = build(:expense, amount_cents: 1234, currency: "JPY")

      expect(described_class.new(expense).amount).to eq("1234")
    end

    it "formats BHD amounts with three decimal places" do
      expense = build(:expense, amount_cents: 1234, currency: "BHD")

      expect(described_class.new(expense).amount).to eq("1.234")
    end

    it "returns nil when the amount is missing" do
      expense = build(:expense, amount_cents: nil)

      expect(described_class.new(expense).amount).to be_nil
    end

    it "returns nil when the currency is missing" do
      expense = build(:expense, currency: nil)

      expect(described_class.new(expense).amount).to be_nil
    end
  end
end
