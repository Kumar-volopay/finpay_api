# frozen_string_literal: true

class AddWorkflowActorIndexesToExpenses < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :expenses, :approved_by_id, algorithm: :concurrently
    add_index :expenses, :rejected_by_id, algorithm: :concurrently
    add_index :expenses, :reimbursed_by_id, algorithm: :concurrently
  end
end
