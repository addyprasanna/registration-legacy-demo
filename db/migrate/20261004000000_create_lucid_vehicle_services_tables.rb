class CreateLucidVehicleServicesTables < ActiveRecord::Migration[7.1]
  def change
    create_table :customer_accounts_customers do |t|
      t.string :customer_number, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :phone
      t.string :address_line1
      t.string :city
      t.string :jurisdiction_code, null: false
      t.string :postal_code
      t.timestamps
    end
    add_index :customer_accounts_customers, :customer_number, unique: true
    add_index :customer_accounts_customers, :email, unique: true
    add_index :customer_accounts_customers, :jurisdiction_code

    create_table :customer_accounts_vehicles do |t|
      t.references :customer, null: false, foreign_key: { to_table: :customer_accounts_customers }
      t.string :vin, null: false
      t.string :model, null: false
      t.integer :model_year, null: false
      t.string :exterior_color
      t.integer :weight_lbs, null: false
      t.integer :purchase_price_cents, null: false
      t.string :powertrain, null: false, default: "bev"
      t.string :financing, null: false, default: "cash"
      t.string :lienholder_name
      t.boolean :lienholder_elt, null: false, default: true
      t.string :usage, null: false, default: "personal"
      t.string :county
      t.date :delivery_date, null: false
      t.timestamps
    end
    add_index :customer_accounts_vehicles, :vin, unique: true

    create_table :registrations do |t|
      t.references :vehicle, null: false, foreign_key: { to_table: :customer_accounts_vehicles }
      t.string :jurisdiction_code, null: false
      t.string :status, null: false, default: "draft"
      t.string :currency, null: false
      t.json :fee_breakdown, null: false, default: []
      t.integer :registration_fee_cents, null: false, default: 0
      t.integer :ev_surcharge_cents, null: false, default: 0
      t.integer :total_cents, null: false, default: 0
      t.string :plate_number
      t.string :dmv_confirmation_number
      t.datetime :submitted_at
      t.timestamps
    end

    create_table :temp_tags do |t|
      t.references :vehicle, null: false, foreign_key: { to_table: :customer_accounts_vehicles }
      t.string :jurisdiction_code, null: false
      t.string :tag_number, null: false
      t.date :issued_on, null: false
      t.integer :valid_days, null: false
      t.date :expires_on, null: false
      t.string :status, null: false, default: "active"
      t.timestamps
    end
    add_index :temp_tags, :tag_number, unique: true

    create_table :lien_filings do |t|
      t.references :vehicle, null: false, foreign_key: { to_table: :customer_accounts_vehicles }
      t.string :jurisdiction_code, null: false
      t.string :financing, null: false
      t.string :lienholder_name
      t.boolean :elt_participant, null: false, default: false
      t.boolean :required, null: false, default: false
      t.string :filing_method
      t.string :reason
      t.string :status, null: false, default: "not_required"
      t.timestamps
    end

    create_table :title_applications do |t|
      t.references :vehicle, null: false, foreign_key: { to_table: :customer_accounts_vehicles }
      t.string :jurisdiction_code, null: false
      t.string :application_number, null: false
      t.string :status, null: false, default: "draft"
      t.string :title_number
      t.json :status_history, null: false, default: []
      t.datetime :submitted_at
      t.datetime :issued_at
      t.timestamps
    end
    add_index :title_applications, :application_number, unique: true

    create_table :dealer_portal_deliveries do |t|
      t.references :vehicle, null: false, foreign_key: { to_table: :customer_accounts_vehicles }
      t.string :delivery_center, null: false
      t.date :scheduled_on, null: false
      t.string :status, null: false, default: "scheduled"
      t.timestamps
    end
  end
end
