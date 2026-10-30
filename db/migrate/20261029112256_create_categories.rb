class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :categories, :name, unique: true

    add_check_constraint :categories,
                         "length(trim(name)) > 0",
                         name: "categories_name_not_blank"
  end
end
