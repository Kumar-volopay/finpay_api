# frozen_string_literal: true

class AddActivityLogDatabaseProtections < ActiveRecord::Migration[8.1]
  def up
    add_check_constraint :activity_logs,
      "action IN ('approve', 'reject', 'reimburse')",
      name: "activity_logs_action_check",
      validate: false

    add_check_constraint :activity_logs,
      "from_state IN ('pending', 'approved', 'rejected', 'reimbursed', 'archived')",
      name: "activity_logs_from_state_check",
      validate: false

    add_check_constraint :activity_logs,
      "to_state IN ('pending', 'approved', 'rejected', 'reimbursed', 'archived')",
      name: "activity_logs_to_state_check",
      validate: false

    safety_assured do
      execute <<~SQL
        CREATE FUNCTION prevent_activity_log_mutation()
        RETURNS trigger AS $$
        BEGIN
          RAISE EXCEPTION 'Activity logs cannot be modified or deleted';
        END;
        $$ LANGUAGE plpgsql;

        CREATE TRIGGER prevent_activity_log_mutation
        BEFORE UPDATE OR DELETE ON activity_logs
        FOR EACH ROW EXECUTE FUNCTION prevent_activity_log_mutation();
      SQL
    end
  end

  def down
    safety_assured do
      execute "DROP TRIGGER IF EXISTS prevent_activity_log_mutation ON activity_logs"
      execute "DROP FUNCTION IF EXISTS prevent_activity_log_mutation()"
    end

    remove_check_constraint :activity_logs, name: "activity_logs_action_check"
    remove_check_constraint :activity_logs, name: "activity_logs_from_state_check"
    remove_check_constraint :activity_logs, name: "activity_logs_to_state_check"
  end
end
