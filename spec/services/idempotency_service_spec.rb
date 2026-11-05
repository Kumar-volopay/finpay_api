
# frozen_string_literal: true

require "rails_helper"

RSpec.describe IdempotencyService do
  let(:category) { create(:category) }
  let(:employee) { create(:user, role: :member) }

  let(:expense) do
    create(:expense, user: employee, category: category)
  end

  let(:fingerprint) { "fingerprint-001" }
  let(:key) { "idempotency-001" }

  describe "#call" do
    it "creates a new idempotency key" do
      result = described_class.call(
        expense: expense,
        actor: employee,
        key: key,
        fingerprint: fingerprint
      )

      expect(result.success?).to be(true)
      expect(result.replayed?).to be(false)
      expect(result.record).to be_persisted
      expect(result.record.expense).to eq(expense)
    end

    it "recognizes a previously completed request" do
      first_result = described_class.call(
        expense: expense,
        actor: employee,
        key: key,
        fingerprint: fingerprint
      )

      first_result.record.update!(
        response_status: 200,
        response_body: {
          "expense_id" => expense.id,
          "status" => "reimbursed"
        }
      )

      second_result = described_class.call(
        expense: expense,
        actor: employee,
        key: key,
        fingerprint: fingerprint
      )

      expect(second_result.success?).to be(true)
      expect(second_result.replayed?).to be(true)
      expect(second_result.response_status).to eq(200)
      expect(second_result.response_body).to eq(
        "expense_id" => expense.id,
        "status" => "reimbursed"
      )
    end

it "rejects a key already used for another expense" do
  another_expense = create(
    :expense,
    user: employee,
    category: category
  )

  described_class.call(
    expense: expense,
    actor: employee,
    key: key,
    fingerprint: fingerprint
  )

  expect {
    described_class.call(
      expense: another_expense,
      actor: employee,
      key: key,
      fingerprint: fingerprint
    )
  }.to raise_error(DomainErrors::IdempotencyKeyUsed)
end

it "rejects the same key with a different fingerprint" do
  described_class.call(
    expense: expense,
    actor: employee,
    key: key,
    fingerprint: fingerprint
  )

  expect {
    described_class.call(
      expense: expense,
      actor: employee,
      key: key,
      fingerprint: "different-fingerprint"
    )
  }.to raise_error(DomainErrors::IdempotencyFingerprintMismatch)
end

    it "rejects a missing idempotency key" do
      result = described_class.call(
        expense: expense,
        actor: employee,
        key: nil,
        fingerprint: fingerprint
      )

      expect(result.success?).to be(false)
      expect(result.response_status).to eq(400)
    end

    it "rejects a missing request fingerprint" do
      result = described_class.call(
        expense: expense,
        actor: employee,
        key: key,
        fingerprint: nil
      )

      expect(result.success?).to be(false)
    end
  end
end
