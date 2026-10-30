class ValidateReceiptMetadataNotNull < ActiveRecord::Migration[8.1]
  def up
    validate_check_constraint :receipts,
                              name: "receipts_file_name_not_null"

    validate_check_constraint :receipts,
                              name: "receipts_content_type_not_null"

    validate_check_constraint :receipts,
                              name: "receipts_byte_size_not_null"

    change_column_null :receipts, :file_name, false
    change_column_null :receipts, :content_type, false
    change_column_null :receipts, :byte_size, false

    remove_check_constraint :receipts,
                            name: "receipts_file_name_not_null"

    remove_check_constraint :receipts,
                            name: "receipts_content_type_not_null"

    remove_check_constraint :receipts,
                            name: "receipts_byte_size_not_null"
  end

  def down
    change_column_null :receipts, :file_name, true
    change_column_null :receipts, :content_type, true
    change_column_null :receipts, :byte_size, true
  end
end
