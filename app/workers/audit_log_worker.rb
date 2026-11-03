# frozen_string_literal: true

class AuditLogWorker < TenantWorker
  sidekiq_options queue: :critical, retry: 5

  def perform_for_tenant(
    expense_id,
    actor_id,
    action,
    from_state = nil,
    to_state = nil,
    event_key = nil
  )
    expense = Expense.find(expense_id)

    # Support jobs enqueued using the previous argument format.
    if event_key.nil?
      event_key = action
      action = "create"
      from_state = "new"
      to_state = expense.status
    end

    actor = User.find(actor_id)

    ActivityLog.create_or_find_by!(event_key: event_key) do |log|
      log.expense = expense
      log.actor = actor
      log.action = action
      log.from_state = from_state
      log.to_state = to_state
    end
  end
end
