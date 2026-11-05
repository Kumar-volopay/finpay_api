# frozen_string_literal: true

class AddExpiresAtToIdempotencyKeys < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :idempotency_keys, :expires_at, :datetime

    add_index :idempotency_keys, :expires_at,
              algorithm: :concurrently
  end
end
