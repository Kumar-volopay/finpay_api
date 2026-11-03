# frozen_string_literal: true

class OverdueReminderWorker < TenantWorker
  sidekiq_options queue: :default, retry: 5

  def perform_for_tenant
    overdue_days = ENV.fetch("OVERDUE_EXPENSE_DAYS", 7).to_i
    raise ArgumentError, "OVERDUE_EXPENSE_DAYS must be positive" unless overdue_days.positive?

    reminder_date = Date.current
    cutoff_date = reminder_date - overdue_days.days

    Expense.where(status: :pending)
           .where("incurred_on <= ?", cutoff_date)
           .find_each do |expense|
      Reminder.create_or_find_by!(
        expense: expense,
        reminder_date: reminder_date,
        reminder_type: "overdue"
      )
    end
  end
end
