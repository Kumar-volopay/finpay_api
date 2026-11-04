class AddMetadataToActivityLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :activity_logs, :metadata, :jsonb,
               null: false, default: {}
  end
end
