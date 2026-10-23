class RestoreCompaniesTableToPublic < ActiveRecord::Migration[8.1]
  def up
    unless table_exists?("public.companies")
      create_table "public.companies" do |t|
        t.string :name, null: false
        t.string :subdomain, null: false
        t.timestamps
      end

      add_index "public.companies", :subdomain, unique: true
    end
  end

  def down
    drop_table "public.companies" if table_exists?("public.companies")
  end
end
