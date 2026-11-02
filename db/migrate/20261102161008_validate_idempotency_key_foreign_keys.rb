# frozen_string_literal: true

class ValidateIdempotencyKeyForeignKeys < ActiveRecord::Migration[8.1]
  def up
    validate_foreign_key :idempotency_keys, :expenses
  end

  def down
    # Keep the foreign key in place when reverting validation.
  end
end
