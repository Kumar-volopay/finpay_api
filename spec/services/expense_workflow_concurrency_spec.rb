# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExpenseWorkflowService do
  describe "concurrent expense approval" do
    self.use_transactional_tests = false

    let(:category) { create(:category) }
    let(:employee) { create(:user, role: :member) }
    let(:admin) { create(:user, role: :admin) }

    let(:expense) do
      create(
        :expense,
        user: employee,
        category: category,
        status: :pending
      )
    end

    it "allows only one thread to approve the same expense" do
      expense_record = expense
      admin_record = admin

      ready = Queue.new
      start = Queue.new
      results = Queue.new

      threads = 2.times.map do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            ready << true
            start.pop

            result = described_class.call(
              expense: Expense.find(expense_record.id),
              actor: User.find(admin_record.id),
              action: :approve
            )

            results << result.success?
          end
        rescue StandardError => e
          results << e
        end
      end

      2.times { ready.pop }
      2.times { start << true }

      threads.each(&:join)

      outcomes = 2.times.map { results.pop }

      expect(outcomes).not_to include(an_instance_of(StandardError))
      expect(outcomes.count(true)).to eq(1)
      expect(outcomes.count(false)).to eq(1)

      expect(expense_record.reload).to be_approved
      expect(ActivityLog.where(expense: expense_record).count).to eq(1)
    ensure
      threads&.each { |thread| thread.kill if thread.alive? }
      ActivityLog.where(expense: expense_record).delete_all if expense_record&.persisted?
      Expense.where(id: expense_record&.id).delete_all if expense_record&.persisted?
      User.where(id: [ employee&.id, admin&.id ].compact).delete_all
      Category.where(id: category&.id).delete_all
    end
  end
end
