# frozen_string_literal: true

class AllowArchiveActivityLogAction < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :activity_logs,
                             name: "activity_logs_action_check"

    add_check_constraint :activity_logs,
                         "action IN ('approve', 'reject', 'reimburse', 'archive')",
                         name: "activity_logs_action_check",
                         validate: false
  end

  def down
    remove_check_constraint :activity_logs,
                             name: "activity_logs_action_check"

    add_check_constraint :activity_logs,
                         "action IN ('approve', 'reject', 'reimburse')",
                         name: "activity_logs_action_check",
                         validate: false
  end
end
