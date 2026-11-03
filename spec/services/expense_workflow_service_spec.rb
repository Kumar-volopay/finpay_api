
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExpenseWorkflowService do
  let(:category) { create(:category) }
  let(:employee) { create(:user, role: :member) }
  let(:admin) { create(:user, role: :admin) }

  let(:expense) do
    create(:expense, user: employee, category: category, status: :pending)
  end

  describe "#call" do
    context "when approving an expense" do
      it "approves a pending expense" do
        result = described_class.call(
          expense: expense,
          company_id: 1,
          actor: admin,
          action: :approve
        )

        expect(result.success?).to be(true)
        expect(expense.reload).to be_approved
        expect(expense.approved_by).to eq(admin)
        expect(expense.approved_at).to be_present
      end

      it "enqueues an audit job for approval" do
        expect(AuditLogWorker).to receive(:perform_async).with(
          1,
          expense.id,
          admin.id,
          "approve",
          "pending",
          "approved",
          "expense:#{expense.id}:approve:v1"
        ).once

        result = described_class.call(
          expense: expense,
          company_id: 1,
          actor: admin,
          action: :approve
        )

        expect(result.success?).to be(true)
      end
    end

    context "when rejecting an expense" do
      it "rejects a pending expense" do
        result = described_class.call(
          expense: expense,
          company_id: 1,
          actor: admin,
          action: :reject
        )

        expect(result.success?).to be(true)
        expect(expense.reload).to be_rejected
        expect(expense.rejected_by).to eq(admin)
        expect(expense.rejected_at).to be_present
      end
    end

    context "when reimbursing an expense" do
      let(:approved_expense) do
        create(
          :expense,
          user: employee,
          category: category,
          status: :approved
        )
      end

      it "reimburses an approved expense" do
        result = described_class.call(
          expense: approved_expense,
          company_id: 1,
          actor: admin,
          action: :reimburse,
          idempotency_key: "reimburse-001",
          request_fingerprint: "fingerprint-001"
        )

        expect(result.success?).to be(true)
        expect(approved_expense.reload).to be_reimbursed
        expect(approved_expense.reimbursed_by).to eq(admin)
        expect(approved_expense.reimbursed_at).to be_present
      end

      it "fails when the idempotency key is missing" do
        result = described_class.call(
          expense: approved_expense,
          company_id: 1,
          actor: admin,
          action: :reimburse,
          request_fingerprint: "fingerprint-001"
        )

        expect(result.success?).to be(false)
        expect(result.response_status).to eq(400)
        expect(approved_expense.reload).to be_approved
      end

      it "replays the original response for the same request" do
        allow(AuditLogWorker).to receive(:perform_async)

        first_result = described_class.call(
          expense: approved_expense,
          company_id: 1,
          actor: admin,
          action: :reimburse,
          idempotency_key: "reimburse-002",
          request_fingerprint: "fingerprint-002"
        )

        second_result = described_class.call(
          expense: approved_expense,
          company_id: 1,
          actor: admin,
          action: :reimburse,
          idempotency_key: "reimburse-002",
          request_fingerprint: "fingerprint-002"
        )

        expect(first_result.success?).to be(true)
        expect(second_result.success?).to be(true)
        expect(second_result.replayed?).to be(true)
        expect(second_result.response_body).to eq("expense_id" => approved_expense.id, "status" => "reimbursed")
        expect(AuditLogWorker).to have_received(:perform_async).once
      end
    end

    context "when a transition is invalid" do
      it "does not approve an already approved expense" do
        approved_expense = create(
          :expense,
          user: employee,
          category: category,
          status: :approved
        )

        result = described_class.call(
          expense: approved_expense,
          company_id: 1,
          actor: admin,
          action: :approve
        )

        expect(result.success?).to be(false)
        expect(approved_expense.reload).to be_approved
        expect(ActivityLog.where(expense: approved_expense)).to be_empty
      end

      it "does not reimburse a pending expense" do
        result = described_class.call(
          expense: expense,
          company_id: 1,
          actor: admin,
          action: :reimburse,
          idempotency_key: "reimburse-003",
          request_fingerprint: "fingerprint-003"
        )

        expect(result.success?).to be(false)
        expect(expense.reload).to be_pending
        expect(ActivityLog.where(expense: expense)).to be_empty
      end
    end

    context "when the action is unsupported" do
      it "returns a failure result" do
        result = described_class.call(
          expense: expense,
          company_id: 1,
          actor: admin,
          action: :invalid_action
        )

        expect(result.success?).to be(false)
        expect(result.error).to eq("Unsupported workflow action")
      end
    end

    context "when the transaction rolls back" do
      it "does not enqueue an audit job" do
        allow(AuditLogWorker).to receive(:perform_async)

        ActiveRecord::Base.transaction(requires_new: true) do
          described_class.call(
            expense: expense,
            company_id: 1,
            actor: admin,
            action: :approve
          )

          raise ActiveRecord::Rollback
        end

        expect(AuditLogWorker).not_to have_received(:perform_async)
      end
    end
  end
end
