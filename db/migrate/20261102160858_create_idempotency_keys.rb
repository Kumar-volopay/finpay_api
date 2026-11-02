# frozen_string_literal: true

class CreateIdempotencyKeys < ActiveRecord::Migration[8.1]
  def up
    create_table :idempotency_keys do |t|
      t.string :key, null: false
      t.bigint :expense_id, null: false
      t.string :request_fingerprint, null: false
      t.integer :response_status
      t.jsonb :response_body
      t.timestamps
    end

    add_index :idempotency_keys, [ :key, :expense_id ], unique: true

    add_foreign_key :idempotency_keys, :expenses, validate: false
  end

  def down
    drop_table :idempotency_keys, if_exists: true
  end
end
