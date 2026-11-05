# frozen_string_literal: true

class ValidateExpenseWorkflowForeignKeys < ActiveRecord::Migration[8.1]
  def up
    validate_foreign_key :expenses, column: :approved_by_id
    validate_foreign_key :expenses, column: :rejected_by_id
    validate_foreign_key :expenses, column: :reimbursed_by_id
  end

  def down
    # Keep the foreign keys in place when reverting validation.
  end
end
