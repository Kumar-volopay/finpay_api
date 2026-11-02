# frozen_string_literal: true

class ValidateActivityLogForeignKeys < ActiveRecord::Migration[8.1]
  def up
    validate_foreign_key :activity_logs, :expenses
    validate_foreign_key :activity_logs, :users, column: :actor_id
  end

  def down
    # Keep the foreign keys in place when reverting validation.
  end
end
