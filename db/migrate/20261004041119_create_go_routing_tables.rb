class CreateGoRoutingTables < ActiveRecord::Migration[7.1]
  def change
    create_table :go_routing_routes do |t|
      t.string :jurisdiction_code, null: false
      t.string :mode, null: false, default: "legacy"
      t.string :updated_by
      t.timestamps
    end
    add_index :go_routing_routes, :jurisdiction_code, unique: true
    add_check_constraint :go_routing_routes, "mode IN ('legacy', 'shadow', 'go')", name: "go_routing_routes_mode"

    create_table :go_routing_comparisons do |t|
      t.string :jurisdiction_code, null: false
      t.string :mode, null: false
      t.string :outcome, null: false
      t.integer :legacy_status
      t.integer :go_status
      t.json :request_params
      t.json :legacy_body
      t.json :go_body
      t.integer :latency_ms
      t.timestamps
    end
    add_index :go_routing_comparisons, %i[jurisdiction_code created_at]
  end
end
