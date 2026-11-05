# frozen_string_literal: true

class CreateIdempotencyKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :idempotency_keys do |t|
      t.string :key, null: false, limit: 255
      t.references :expense, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.string :request_fingerprint, null: false
      t.integer :response_status
      t.jsonb :response_body
      t.timestamps
    end

    add_index :idempotency_keys, [ :actor_id, :key ], unique: true
  end
end
