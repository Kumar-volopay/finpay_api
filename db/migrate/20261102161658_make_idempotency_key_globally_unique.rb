# frozen_string_literal: true

class MakeIdempotencyKeyGloballyUnique < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!
  def up
    remove_index :idempotency_keys, [ :key, :expense_id ],
                 name: "index_idempotency_keys_on_key_and_expense_id"

    add_index :idempotency_keys, :key, unique: true,
              algorithm: :concurrently
  end

  def down
    remove_index :idempotency_keys, :key,
                 algorithm: :concurrently,
                 if_exists: true

    add_index :idempotency_keys, [ :key, :expense_id ], unique: true
  end
end
