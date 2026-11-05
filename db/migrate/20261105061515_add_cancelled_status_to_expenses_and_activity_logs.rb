# frozen_string_literal: true

class AddCancelledStatusToExpensesAndActivityLogs < ActiveRecord::Migration[8.1]
  def change
    remove_check_constraint :expenses, name: "expenses_status_valid"
    add_check_constraint :expenses,
                         "status::text = ANY (ARRAY['pending', 'approved', 'rejected', 'reimbursed', 'archived', 'cancelled']::text[])",
                         name: "expenses_status_valid"

    remove_check_constraint :activity_logs, name: "activity_logs_from_state_check"
    add_check_constraint :activity_logs,
                         "from_state::text = ANY (ARRAY['new', 'pending', 'approved', 'rejected', 'reimbursed', 'archived', 'cancelled']::text[])",
                         name: "activity_logs_from_state_check"

    remove_check_constraint :activity_logs, name: "activity_logs_to_state_check"
    add_check_constraint :activity_logs,
                         "to_state::text = ANY (ARRAY['pending', 'approved', 'rejected', 'reimbursed', 'archived', 'cancelled']::text[])",
                         name: "activity_logs_to_state_check"
  end
end
