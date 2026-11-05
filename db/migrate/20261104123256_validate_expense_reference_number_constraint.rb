# frozen_string_literal: true

class ValidateExpenseReferenceNumberConstraint < ActiveRecord::Migration[8.1]
  def change
    validate_check_constraint :expenses,
                              name: "expenses_reference_number_not_null"
  end
end
