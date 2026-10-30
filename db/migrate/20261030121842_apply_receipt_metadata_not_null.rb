class ApplyReceiptMetadataNotNull < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :receipts,
                         "file_name IS NOT NULL",
                         name: "receipts_file_name_not_null",
                         validate: false

    add_check_constraint :receipts,
                         "content_type IS NOT NULL",
                         name: "receipts_content_type_not_null",
                         validate: false

    add_check_constraint :receipts,
                         "byte_size IS NOT NULL",
                         name: "receipts_byte_size_not_null",
                         validate: false
  end
end
