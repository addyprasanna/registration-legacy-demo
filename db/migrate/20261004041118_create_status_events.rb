class CreateStatusEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :status_events do |t|
      t.references :vehicle, null: false, foreign_key: { to_table: :customer_accounts_vehicles }, index: false
      t.string :domain, null: false
      t.string :subject_type
      t.integer :subject_id
      t.string :event, null: false
      t.string :from_status
      t.string :to_status
      t.datetime :occurred_at, null: false
      t.json :metadata, default: {}
      t.timestamps
    end

    add_index :status_events, %i[vehicle_id occurred_at]
  end
end
