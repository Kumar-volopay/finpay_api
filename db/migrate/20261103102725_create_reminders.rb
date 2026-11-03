# frozen_string_literal: true

class CreateReminders < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    create_table :reminders do |t|
      t.references :expense, null: false, foreign_key: true
      t.date :reminder_date, null: false
      t.string :reminder_type, null: false, default: "overdue"

      t.timestamps
    end

    add_index :reminders,
              [ :expense_id, :reminder_date, :reminder_type ],
              unique: true,
              algorithm: :concurrently,
              name: "index_reminders_on_expense_date_and_type"
  end
end
