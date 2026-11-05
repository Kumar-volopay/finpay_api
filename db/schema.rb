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

ActiveRecord::Schema[8.1].define(version: 2026_11_05_064724) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "activity_logs", force: :cascade do |t|
    t.bigint "expense_id", null: false
    t.bigint "actor_id", null: false
    t.string "action", null: false
    t.string "from_state", null: false
    t.string "to_state", null: false
    t.datetime "created_at", null: false
    t.string "event_key"
    t.jsonb "metadata", default: {}, null: false
    t.index ["actor_id"], name: "index_activity_logs_on_actor_id"
    t.index ["event_key"], name: "index_activity_logs_on_event_key", unique: true
    t.index ["expense_id", "created_at"], name: "index_activity_logs_on_expense_id_and_created_at"
    t.check_constraint "action::text = ANY (ARRAY['create'::character varying, 'approve'::character varying, 'reject'::character varying, 'reimburse'::character varying, 'archive'::character varying]::text[])", name: "activity_logs_action_check"
    t.check_constraint "from_state::text = ANY (ARRAY['new'::character varying, 'pending'::character varying, 'approved'::character varying, 'rejected'::character varying, 'reimbursed'::character varying, 'archived'::character varying]::text[])", name: "activity_logs_from_state_check"
  end

  add_check_constraint "activity_logs", "to_state::text = ANY (ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying, 'reimbursed'::character varying, 'archived'::character varying]::text[])", name: "activity_logs_to_state_check", validate: false

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_categories_on_lower_name", unique: true
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
    t.bigint "approved_by_id"
    t.datetime "approved_at"
    t.bigint "rejected_by_id"
    t.datetime "rejected_at"
    t.bigint "reimbursed_by_id"
    t.datetime "reimbursed_at"
    t.index ["approved_by_id"], name: "index_expenses_on_approved_by_id"
    t.index ["category_id"], name: "index_expenses_on_category_id"
    t.index ["reimbursed_by_id"], name: "index_expenses_on_reimbursed_by_id"
    t.index ["rejected_by_id"], name: "index_expenses_on_rejected_by_id"
    t.index ["user_id", "incurred_on"], name: "index_expenses_on_user_id_and_incurred_on"
    t.index ["user_id", "status"], name: "index_expenses_on_user_id_and_status"
    t.index ["user_id"], name: "index_expenses_on_user_id"
    t.check_constraint "amount_cents > 0", name: "expenses_amount_cents_positive"
    t.check_constraint "currency::text ~ '^[A-Z]{3}$'::text", name: "expenses_currency_format"
    t.check_constraint "length(TRIM(BOTH FROM title)) > 0", name: "expenses_title_not_blank"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying, 'reimbursed'::character varying, 'archived'::character varying, 'cancelled'::character varying]::text[])", name: "expenses_status_valid"
  end

  add_check_constraint "expenses", "approved_by_id IS DISTINCT FROM user_id", name: "expenses_prevent_self_approval", validate: false

  create_table "idempotency_keys", force: :cascade do |t|
    t.string "key", limit: 255, null: false
    t.bigint "expense_id", null: false
    t.bigint "actor_id", null: false
    t.string "request_fingerprint", null: false
    t.integer "response_status"
    t.jsonb "response_body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "expires_at"
    t.index ["actor_id", "key"], name: "index_idempotency_keys_on_actor_id_and_key", unique: true
    t.index ["actor_id"], name: "index_idempotency_keys_on_actor_id"
    t.index ["expense_id"], name: "index_idempotency_keys_on_expense_id"
    t.index ["expires_at"], name: "index_idempotency_keys_on_expires_at"
  end

  create_table "invitations", force: :cascade do |t|
    t.string "email", null: false
    t.string "token_digest", null: false
    t.integer "role", default: 1, null: false
    t.bigint "invited_by_id", null: false
    t.datetime "expires_at", null: false
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_invitations_on_email"
    t.index ["invited_by_id"], name: "index_invitations_on_invited_by_id"
    t.index ["token_digest"], name: "index_invitations_on_token_digest", unique: true
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
    t.index ["storage_key"], name: "index_receipts_on_storage_key", unique: true
    t.check_constraint "byte_size >= 0", name: "receipts_byte_size_nonnegative"
    t.check_constraint "length(TRIM(BOTH FROM storage_key)) > 0", name: "receipts_storage_key_not_blank"
    t.check_constraint "ocr_status::text = ANY (ARRAY['pending'::character varying::text, 'processing'::character varying::text, 'completed'::character varying::text, 'failed'::character varying::text])", name: "receipts_ocr_status_valid"
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token_digest", null: false
    t.datetime "expires_at", null: false
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "family_id", null: false
    t.index ["family_id"], name: "index_refresh_tokens_on_family_id"
    t.index ["token_digest"], name: "index_refresh_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "reminders", force: :cascade do |t|
    t.bigint "expense_id", null: false
    t.date "reminder_date", null: false
    t.string "reminder_type", default: "overdue", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expense_id", "reminder_date", "reminder_type"], name: "index_reminders_on_expense_date_and_type", unique: true
    t.index ["expense_id"], name: "index_reminders_on_expense_id"
    t.check_constraint "reminder_type::text = 'overdue'::text", name: "reminders_type_check"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "role", default: 1, null: false
    t.string "jti", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "disabled_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
  end

  add_foreign_key "activity_logs", "expenses"
  add_foreign_key "activity_logs", "users", column: "actor_id"
  add_foreign_key "expenses", "categories"
  add_foreign_key "expenses", "users"
  add_foreign_key "expenses", "users", column: "approved_by_id"
  add_foreign_key "expenses", "users", column: "reimbursed_by_id"
  add_foreign_key "expenses", "users", column: "rejected_by_id"
  add_foreign_key "idempotency_keys", "expenses"
  add_foreign_key "idempotency_keys", "users", column: "actor_id"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "receipts", "expenses"
  add_foreign_key "refresh_tokens", "users"
  add_foreign_key "reminders", "expenses"
end
