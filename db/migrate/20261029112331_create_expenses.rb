class CreateExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :expenses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true

      t.string :title, null: false
      t.bigint :amount_cents, null: false
      t.string :currency, limit: 3, null: false
      t.string :status, null: false, default: "pending"
      t.date :incurred_on, null: false
      t.text :notes

      t.timestamps
    end

    add_check_constraint :expenses,
                         "amount_cents > 0",
                         name: "expenses_amount_cents_positive"

    add_check_constraint :expenses,
                         "currency ~ '^[A-Z]{3}$'",
                         name: "expenses_currency_format"

    add_check_constraint :expenses,
                         "length(trim(title)) > 0",
                         name: "expenses_title_not_blank"

    add_check_constraint :expenses,
                         "status IN ('pending', 'approved', 'rejected')",
                         name: "expenses_status_valid"

    add_index :expenses, [ :user_id, :incurred_on ]
    add_index :expenses, [ :user_id, :status ]
  end
end
