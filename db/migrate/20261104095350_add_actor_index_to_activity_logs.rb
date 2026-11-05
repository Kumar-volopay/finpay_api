# frozen_string_literal: true

class AddActorIndexToActivityLogs < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :activity_logs, :actor_id, algorithm: :concurrently
  end
end
