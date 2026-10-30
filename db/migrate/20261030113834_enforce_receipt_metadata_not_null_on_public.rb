class EnforceReceiptMetadataNotNullOnPublic < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  CONSTRAINT_NAME = "receipts_metadata_not_null"

  def up
    schema = connection.current_schema
    table = "#{connection.quote_table_name(schema)}.#{connection.quote_table_name('receipts')}"

    safety_assured do
      execute <<~SQL
        ALTER TABLE #{table}
        ADD CONSTRAINT #{CONSTRAINT_NAME}
        CHECK (
          file_name IS NOT NULL
          AND content_type IS NOT NULL
          AND byte_size IS NOT NULL
        ) NOT VALID
      SQL

      execute <<~SQL
        ALTER TABLE #{table}
        VALIDATE CONSTRAINT #{CONSTRAINT_NAME}
      SQL
    end
  end

  def down
    schema = connection.current_schema
    table = "#{connection.quote_table_name(schema)}.#{connection.quote_table_name('receipts')}"

    safety_assured do
      execute <<~SQL
        ALTER TABLE #{table}
        DROP CONSTRAINT IF EXISTS #{CONSTRAINT_NAME}
      SQL
    end
  end
end
