class EnforceReceiptMetadataNotNull < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :receipts,
                         "file_name IS NOT NULL AND content_type IS NOT NULL AND byte_size IS NOT NULL",
                         name: "receipts_metadata_not_null",
                         validate: false

    validate_check_constraint :receipts,
                              name: "receipts_metadata_not_null"

    change_column_null :receipts, :file_name, false
    change_column_null :receipts, :content_type, false
    change_column_null :receipts, :byte_size, false

    remove_check_constraint :receipts,
                             name: "receipts_metadata_not_null"
  end
end
