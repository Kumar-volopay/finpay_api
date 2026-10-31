class CreateJwtDenylists < ActiveRecord::Migration[8.1]
  def change
    create_table "public.jwt_denylist" do |t|
      t.string :jti, null: false
      t.datetime :exp, null: false
    end

    add_index "public.jwt_denylist", :jti, unique: true
    add_index "public.jwt_denylist", :exp
  end
end
