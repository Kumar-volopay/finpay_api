
# frozen_string_literal: true

require "rails_helper"

RSpec.describe IdempotencyKey do
  let(:category) { create(:category) }
  let(:employee) { create(:user, role: :member) }

  let(:expense) do
    create(:expense, user: employee, category: category)
  end

  describe "associations" do
    it "belongs to an expense" do
      expect(described_class.reflect_on_association(:expense).macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    it "requires an idempotency key" do
      record = build(
        :idempotency_key,
        expense: expense,
        actor: employee,
        key: nil
      )

      expect(record).not_to be_valid
    end

    it "requires a request fingerprint" do
      record = build(
        :idempotency_key,
        expense: expense,
        request_fingerprint: nil
      )

      expect(record).not_to be_valid
    end

    it "rejects duplicate keys globally" do
      create(
        :idempotency_key,
        expense: expense,
        actor: employee,
        key: "global-key-001"
      )

      another_expense = create(
        :expense,
        user: employee,
        category: category
      )

      duplicate = build(
        :idempotency_key,
        expense: another_expense,
        actor: employee,
        key: "global-key-001"
      )

      expect(duplicate).to be_valid
      expect {
        duplicate.save!
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "accepts a different idempotency key" do
      create(
        :idempotency_key,
        expense: expense,
        actor: employee,
        key: "global-key-002"
      )

      another_expense = create(
        :expense,
        user: employee,
        category: category
      )

      record = build(
        :idempotency_key,
        expense: another_expense,
        actor: employee,
        key: "global-key-003"
      )

      expect(record).to be_valid
    end
  end
end
