# frozen_string_literal: true

class ValidateReminderTypeCheckConstraint < ActiveRecord::Migration[8.1]
  def change
    validate_check_constraint :reminders,
                               name: "reminders_type_check"
  end
end
