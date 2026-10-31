class CreateReceipts < ActiveRecord::Migration[8.1]
  def change
    create_table :receipts do |t|
      t.references :expense, null: false, foreign_key: true

      t.string :file_name
      t.string :content_type
      t.bigint :byte_size
      t.string :storage_key, null: false
      t.string :ocr_status, null: false, default: "pending"
      t.text :ocr_text

      t.timestamps
    end

    add_check_constraint :receipts,
                         "length(trim(storage_key)) > 0",
                         name: "receipts_storage_key_not_blank"

    add_check_constraint :receipts,
                         "byte_size IS NULL OR byte_size >= 0",
                         name: "receipts_byte_size_nonnegative"
  end
end
