# frozen_string_literal: true

class AddCompositeIndexToExpenses < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :expenses,
              [ :user_id, :status, :incurred_on ],
              name: "index_expenses_on_user_status_incurred",
              algorithm: :concurrently
  end
end
