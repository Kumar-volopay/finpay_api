# frozen_string_literal: true

class CreateReminders < ActiveRecord::Migration[8.1]
  def change
    create_table :reminders do |t|
      t.references :expense, null: false, foreign_key: true
      t.date :reminder_date, null: false
      t.string :reminder_type, null: false, default: "overdue"

      t.timestamps

      t.index [ :expense_id, :reminder_date, :reminder_type ],
              unique: true,
              name: "index_reminders_on_expense_date_and_type"
    end

    add_check_constraint :reminders,
                         "reminder_type = 'overdue'",
                         name: "reminders_type_check"
  end
end
