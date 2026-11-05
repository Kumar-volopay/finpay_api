# frozen_string_literal: true

class AddEventKeyToActivityLogs < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :activity_logs, :event_key, :string

    add_index :activity_logs,
              :event_key,
              unique: true,
              algorithm: :concurrently
  end
end
