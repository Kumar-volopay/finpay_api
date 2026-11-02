# frozen_string_literal: true

class CreateActivityLogs < ActiveRecord::Migration[8.1]
  def up
    create_table :activity_logs do |t|
      t.bigint :expense_id, null: false
      t.bigint :actor_id, null: false
      t.string :action, null: false
      t.string :from_state, null: false
      t.string :to_state, null: false
      t.timestamps
    end

    add_index :activity_logs, [ :expense_id, :created_at ]

    add_foreign_key :activity_logs, :expenses, validate: false
    add_foreign_key :activity_logs, :users,
                    column: :actor_id, validate: false
  end

  def down
    drop_table :activity_logs, if_exists: true
  end
end
