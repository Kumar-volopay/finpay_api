# frozen_string_literal: true

class AuditLogWorker < TenantWorker
  sidekiq_options queue: :critical, retry: 5

  def perform_for_tenant(attributes)
    expense_id = attributes.fetch("expense_id")
    actor_id = attributes.fetch("actor_id")
    action = attributes.fetch("action")
    from_state = attributes["from_state"]
    to_state = attributes["to_state"]
    event_key = attributes.fetch("event_key")

    expense = Expense.find_by(id: expense_id)
    unless expense
      Rails.logger.warn("AuditLogWorker skipped: Expense not found (id: #{expense_id})")
      return
    end

    actor = User.find_by(id: actor_id)
    unless actor
      Rails.logger.warn("AuditLogWorker skipped: User not found (id: #{actor_id})")
      return
    end

    ActivityLog.create_or_find_by!(event_key: event_key) do |log|
      log.expense = expense
      log.actor = actor
      log.action = action
      log.from_state = from_state
      log.to_state = to_state
    end
  end
end
