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

ActiveRecord::Schema[7.1].define(version: 2026_10_04_041119) do
  create_table "customer_accounts_customers", force: :cascade do |t|
    t.string "customer_number", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.string "phone"
    t.string "address_line1"
    t.string "city"
    t.string "jurisdiction_code", null: false
    t.string "postal_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_number"], name: "index_customer_accounts_customers_on_customer_number", unique: true
    t.index ["email"], name: "index_customer_accounts_customers_on_email", unique: true
    t.index ["jurisdiction_code"], name: "index_customer_accounts_customers_on_jurisdiction_code"
  end

  create_table "customer_accounts_vehicles", force: :cascade do |t|
    t.integer "customer_id", null: false
    t.string "vin", null: false
    t.string "model", null: false
    t.integer "model_year", null: false
    t.string "exterior_color"
    t.integer "weight_lbs", null: false
    t.integer "purchase_price_cents", null: false
    t.string "powertrain", default: "bev", null: false
    t.string "financing", default: "cash", null: false
    t.string "lienholder_name"
    t.boolean "lienholder_elt", default: true, null: false
    t.string "usage", default: "personal", null: false
    t.string "county"
    t.date "delivery_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_customer_accounts_vehicles_on_customer_id"
    t.index ["vin"], name: "index_customer_accounts_vehicles_on_vin", unique: true
  end

  create_table "dealer_portal_deliveries", force: :cascade do |t|
    t.integer "vehicle_id", null: false
    t.string "delivery_center", null: false
    t.date "scheduled_on", null: false
    t.string "status", default: "scheduled", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vehicle_id"], name: "index_dealer_portal_deliveries_on_vehicle_id"
  end

  create_table "go_routing_comparisons", force: :cascade do |t|
    t.string "jurisdiction_code", null: false
    t.string "mode", null: false
    t.string "outcome", null: false
    t.integer "legacy_status"
    t.integer "go_status"
    t.json "request_params"
    t.json "legacy_body"
    t.json "go_body"
    t.integer "latency_ms"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jurisdiction_code", "created_at"], name: "idx_on_jurisdiction_code_created_at_6a0f0bdc14"
  end

  create_table "go_routing_routes", force: :cascade do |t|
    t.string "jurisdiction_code", null: false
    t.string "mode", default: "legacy", null: false
    t.string "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jurisdiction_code"], name: "index_go_routing_routes_on_jurisdiction_code", unique: true
    t.check_constraint "mode IN ('legacy', 'shadow', 'go')", name: "go_routing_routes_mode"
  end

  create_table "lien_filings", force: :cascade do |t|
    t.integer "vehicle_id", null: false
    t.string "jurisdiction_code", null: false
    t.string "financing", null: false
    t.string "lienholder_name"
    t.boolean "elt_participant", default: false, null: false
    t.boolean "required", default: false, null: false
    t.string "filing_method"
    t.string "reason"
    t.string "status", default: "not_required", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vehicle_id"], name: "index_lien_filings_on_vehicle_id"
  end

  create_table "registrations", force: :cascade do |t|
    t.integer "vehicle_id", null: false
    t.string "jurisdiction_code", null: false
    t.string "status", default: "draft", null: false
    t.string "currency", null: false
    t.json "fee_breakdown", default: [], null: false
    t.integer "registration_fee_cents", default: 0, null: false
    t.integer "ev_surcharge_cents", default: 0, null: false
    t.integer "total_cents", default: 0, null: false
    t.string "plate_number"
    t.string "dmv_confirmation_number"
    t.datetime "submitted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vehicle_id"], name: "index_registrations_on_vehicle_id"
  end

  create_table "status_events", force: :cascade do |t|
    t.integer "vehicle_id", null: false
    t.string "domain", null: false
    t.string "subject_type"
    t.integer "subject_id"
    t.string "event", null: false
    t.string "from_status"
    t.string "to_status"
    t.datetime "occurred_at", null: false
    t.json "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vehicle_id", "occurred_at"], name: "index_status_events_on_vehicle_id_and_occurred_at"
  end

  create_table "temp_tags", force: :cascade do |t|
    t.integer "vehicle_id", null: false
    t.string "jurisdiction_code", null: false
    t.string "tag_number", null: false
    t.date "issued_on", null: false
    t.integer "valid_days", null: false
    t.date "expires_on", null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_number"], name: "index_temp_tags_on_tag_number", unique: true
    t.index ["vehicle_id"], name: "index_temp_tags_on_vehicle_id"
  end

  create_table "title_applications", force: :cascade do |t|
    t.integer "vehicle_id", null: false
    t.string "jurisdiction_code", null: false
    t.string "application_number", null: false
    t.string "status", default: "draft", null: false
    t.string "title_number"
    t.json "status_history", default: [], null: false
    t.datetime "submitted_at"
    t.datetime "issued_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_number"], name: "index_title_applications_on_application_number", unique: true
    t.index ["vehicle_id"], name: "index_title_applications_on_vehicle_id"
  end

  add_foreign_key "customer_accounts_vehicles", "customer_accounts_customers", column: "customer_id"
  add_foreign_key "dealer_portal_deliveries", "customer_accounts_vehicles", column: "vehicle_id"
  add_foreign_key "lien_filings", "customer_accounts_vehicles", column: "vehicle_id"
  add_foreign_key "registrations", "customer_accounts_vehicles", column: "vehicle_id"
  add_foreign_key "status_events", "customer_accounts_vehicles", column: "vehicle_id"
  add_foreign_key "temp_tags", "customer_accounts_vehicles", column: "vehicle_id"
  add_foreign_key "title_applications", "customer_accounts_vehicles", column: "vehicle_id"
end
