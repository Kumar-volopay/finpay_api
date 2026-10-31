# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_31_073331) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
    t.check_constraint "length(TRIM(BOTH FROM name)) > 0", name: "categories_name_not_blank"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name", null: false
    t.string "subdomain", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subdomain"], name: "index_companies_on_subdomain", unique: true
  end

  create_table "expenses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "category_id", null: false
    t.string "title", null: false
    t.bigint "amount_cents", null: false
    t.string "currency", limit: 3, null: false
    t.string "status", default: "pending", null: false
    t.date "incurred_on", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_expenses_on_category_id"
    t.index ["incurred_on"], name: "index_expenses_on_incurred_on"
    t.index ["status"], name: "index_expenses_on_status"
    t.index ["user_id", "status", "incurred_on"], name: "index_expenses_on_user_status_incurred"
    t.index ["user_id"], name: "index_expenses_on_user_id"
    t.check_constraint "amount_cents > 0", name: "expenses_amount_cents_positive"
    t.check_constraint "currency::text ~ '^[A-Z]{3}$'::text", name: "expenses_currency_format"
    t.check_constraint "length(TRIM(BOTH FROM title)) > 0", name: "expenses_title_not_blank"
  end

  create_table "jwt_denylist", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.index ["exp"], name: "index_jwt_denylist_on_exp"
    t.index ["jti"], name: "index_jwt_denylist_on_jti", unique: true
  end

  create_table "receipts", force: :cascade do |t|
    t.bigint "expense_id", null: false
    t.string "file_name", null: false
    t.string "content_type", null: false
    t.bigint "byte_size", null: false
    t.string "storage_key", null: false
    t.string "ocr_status", default: "pending", null: false
    t.text "ocr_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expense_id"], name: "index_receipts_on_expense_id"
    t.check_constraint "byte_size IS NULL OR byte_size >= 0", name: "receipts_byte_size_nonnegative"
    t.check_constraint "file_name IS NOT NULL AND content_type IS NOT NULL AND byte_size IS NOT NULL", name: "receipts_metadata_not_null"
    t.check_constraint "length(TRIM(BOTH FROM storage_key)) > 0", name: "receipts_storage_key_not_blank"
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token_digest", null: false
    t.datetime "expires_at", null: false
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_refresh_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "role", default: 1, null: false
    t.string "jti", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
  end

  add_foreign_key "expenses", "categories"
  add_foreign_key "expenses", "users"
  add_foreign_key "receipts", "expenses"
end
