# frozen_string_literal: true

class ValidateCreationActivityLogValues < ActiveRecord::Migration[8.1]
  def up
    validate_check_constraint :activity_logs,
                               name: "activity_logs_action_check"

    validate_check_constraint :activity_logs,
                               name: "activity_logs_from_state_check"
  end

  def down
    # No rollback needed; the constraints remain in place.
  end
end
