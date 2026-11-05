# frozen_string_literal: true

class OverdueReminderWorker < TenantWorker
  MAX_REMINDERS_PER_EXPENSE = 3

  sidekiq_options queue: :default, retry: 5

  def perform_for_tenant
    overdue_days = ENV.fetch("OVERDUE_EXPENSE_DAYS", "7").to_i

    reminder_date = Date.current
    cutoff_date = reminder_date - overdue_days.days

    already_max_reminded = Reminder
      .where(reminder_type: "overdue")
      .group(:expense_id)
      .having("COUNT(*) >= ?", MAX_REMINDERS_PER_EXPENSE)
      .select(:expense_id)

    expense_ids = Expense
      .where(status: :pending)
      .where("created_at <= ?", cutoff_date.end_of_day)
      .where.not(id: already_max_reminded)
      .pluck(:id)

    return if expense_ids.empty?

    now = Time.current

    reminders = expense_ids.map do |expense_id|
      {
        expense_id: expense_id,
        reminder_date: reminder_date,
        reminder_type: "overdue",
        created_at: now,
        updated_at: now
      }
    end

    Reminder.insert_all(
      reminders,
      unique_by: :index_reminders_on_expense_date_and_type
    )
  end
end
