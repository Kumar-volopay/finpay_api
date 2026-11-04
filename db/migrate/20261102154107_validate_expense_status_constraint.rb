# frozen_string_literal: true

class ValidateExpenseStatusConstraint < ActiveRecord::Migration[8.1]
  def up
    validate_check_constraint :expenses, name: "expenses_status_valid"
  end

  def down
    # PostgreSQL does not support reverting a validated constraint
    # to the NOT VALID state through this migration.
  end
end
