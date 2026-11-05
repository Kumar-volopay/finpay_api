# frozen_string_literal: true

class CreateActivityLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_logs do |t|
      t.references :expense, null: false, foreign_key: true, index: false
      t.references :actor, null: false, foreign_key: { to_table: :users }, index: false

      t.string :action, null: false
      t.string :from_state, null: false
      t.string :to_state, null: false

      t.datetime :created_at, null: false
    end

    add_index :activity_logs, [ :expense_id, :created_at ]
  end
end
