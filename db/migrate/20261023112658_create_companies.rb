class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table "public.companies" do |t|
      t.string :name, null: false
      t.string :subdomain, null: false

      t.timestamps
    end

    add_index "public.companies", :subdomain, unique: true
  end
end
