# frozen_string_literal: true

class UpdateExpenseStatusConstraint < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :expenses, name: "expenses_status_valid" if
      check_constraint_exists?(:expenses, name: "expenses_status_valid")

    add_check_constraint :expenses,
                         "status IN ('pending', 'approved', 'rejected', 'reimbursed', 'archived')",
                         name: "expenses_status_valid",
                         validate: false
  end

  def down
    remove_check_constraint :expenses, name: "expenses_status_valid" if
      check_constraint_exists?(:expenses, name: "expenses_status_valid")

    add_check_constraint :expenses,
                         "status IN ('pending', 'approved', 'rejected')",
                         name: "expenses_status_valid",
                         validate: false
  end
end
