class CreateReceipts < ActiveRecord::Migration[8.1]
  def up
    create_table :receipts do |t|
      t.references :expense, null: false, foreign_key: true
      t.string :file_name, null: false
      t.string :content_type, null: false
      t.bigint :byte_size, null: false
      t.string :storage_key, null: false
      t.string :ocr_status, null: false, default: "pending"
      t.text :ocr_text

      t.timestamps
    end

    add_check_constraint :receipts,
                         "length(trim(storage_key)) > 0",
                         name: "receipts_storage_key_not_blank"

    add_check_constraint :receipts,
                         "byte_size >= 0",
                         name: "receipts_byte_size_nonnegative"

    add_check_constraint :receipts,
                         "ocr_status IN ('pending', 'processing', 'completed', 'failed')",
                         name: "receipts_ocr_status_valid"

    add_index :receipts, :storage_key, unique: true
  end

  def down
    drop_table :receipts, if_exists: true
  end
end
