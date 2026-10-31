class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :encrypted_password, null: false, default: ""
      t.integer :role, null: false, default: 1
      t.string :jti, null: false

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :jti, unique: true
  end
end
