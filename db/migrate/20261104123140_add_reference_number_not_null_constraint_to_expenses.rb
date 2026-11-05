# frozen_string_literal: true

class AddReferenceNumberNotNullConstraintToExpenses < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :expenses,
                         "reference_number IS NOT NULL",
                         name: "expenses_reference_number_not_null",
                         validate: false
  end
end
