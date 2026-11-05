# frozen_string_literal: true

class AllowCreationActivityLogValues < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :activity_logs, name: "activity_logs_action_check"
    add_check_constraint :activity_logs,
                         "action IN ('create', 'approve', 'reject', 'reimburse', 'archive')",
                         name: "activity_logs_action_check",
                         validate: false

    remove_check_constraint :activity_logs, name: "activity_logs_from_state_check"
    add_check_constraint :activity_logs,
                         "from_state IN ('new', 'pending', 'approved', 'rejected', 'reimbursed', 'archived')",
                         name: "activity_logs_from_state_check",
                         validate: false
  end

  def down
    remove_check_constraint :activity_logs, name: "activity_logs_action_check"
    add_check_constraint :activity_logs,
                         "action IN ('approve', 'reject', 'reimburse', 'archive')",
                         name: "activity_logs_action_check",
                         validate: false

    remove_check_constraint :activity_logs, name: "activity_logs_from_state_check"
    add_check_constraint :activity_logs,
                         "from_state IN ('pending', 'approved', 'rejected', 'reimbursed', 'archived')",
                         name: "activity_logs_from_state_check",
                         validate: false
  end
end
