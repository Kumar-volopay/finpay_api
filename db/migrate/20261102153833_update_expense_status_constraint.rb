# frozen_string_literal: true

class UpdateExpenseStatusConstraint < ActiveRecord::Migration[8.1]
  def up
    if check_constraint_exists?(:expenses, name: "expenses_status_valid")
      remove_check_constraint :expenses, name: "expenses_status_valid"
    end

    unless check_constraint_exists?(:expenses, name: "expenses_status_valid")
      add_check_constraint :expenses,
                           "status IN ('pending', 'approved', 'rejected', 'reimbursed', 'archived')",
                           name: "expenses_status_valid",
                           validate: false
    end
  end

  def down
    if check_constraint_exists?(:expenses, name: "expenses_status_valid")
      remove_check_constraint :expenses, name: "expenses_status_valid"
    end

    add_check_constraint :expenses,
                         "status IN ('pending', 'approved', 'rejected')",
                         name: "expenses_status_valid",
                         validate: false
  end
end
