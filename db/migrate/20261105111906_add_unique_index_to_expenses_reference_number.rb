# frozen_string_literal: true

class AddUniqueIndexToExpensesReferenceNumber < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :expenses, :reference_number,
              unique: true,
              algorithm: :concurrently
  end
end
