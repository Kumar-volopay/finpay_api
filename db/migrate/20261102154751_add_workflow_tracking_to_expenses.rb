# frozen_string_literal: true

class AddWorkflowTrackingToExpenses < ActiveRecord::Migration[8.1]
  def up
    add_column :expenses, :approved_by_id, :bigint
    add_column :expenses, :approved_at, :datetime

    add_column :expenses, :rejected_by_id, :bigint
    add_column :expenses, :rejected_at, :datetime

    add_column :expenses, :reimbursed_by_id, :bigint
    add_column :expenses, :reimbursed_at, :datetime

    add_foreign_key :expenses, :users,
                    column: :approved_by_id, validate: false

    add_foreign_key :expenses, :users,
                    column: :rejected_by_id, validate: false

    add_foreign_key :expenses, :users,
                    column: :reimbursed_by_id, validate: false
  end

  def down
    remove_foreign_key :expenses, column: :approved_by_id,
                       if_exists: true
    remove_foreign_key :expenses, column: :rejected_by_id,
                       if_exists: true
    remove_foreign_key :expenses, column: :reimbursed_by_id,
                       if_exists: true

    remove_column :expenses, :approved_by_id
    remove_column :expenses, :approved_at
    remove_column :expenses, :rejected_by_id
    remove_column :expenses, :rejected_at
    remove_column :expenses, :reimbursed_by_id
    remove_column :expenses, :reimbursed_at
  end
end
