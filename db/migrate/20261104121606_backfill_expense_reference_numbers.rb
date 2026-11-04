# frozen_string_literal: true

class BackfillExpenseReferenceNumbers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  class MigrationExpense < ActiveRecord::Base
    self.table_name = "expenses"
  end

  def up
    MigrationExpense.unscoped.where(reference_number: nil).in_batches(of: 1_000) do |batch|
      batch.update_all("reference_number = 'EXP-' || id::text")
      sleep(0.01)
    end
  end

  def down
    MigrationExpense.unscoped
      .where("reference_number = 'EXP-' || id::text")
      .in_batches(of: 1_000) do |batch|
        batch.update_all(reference_number: nil)
        sleep(0.01)
      end
  end
end
