# frozen_string_literal: true

class AddReminderTypeCheckConstraint < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :reminders,
                         "reminder_type = 'overdue'",
                         name: "reminders_type_check",
                         validate: false
  end
end
