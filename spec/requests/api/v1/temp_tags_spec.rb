require "rails_helper"

RSpec.describe "API v1 temporary tags", type: :request do
  let!(:customer) do
    CustomerAccounts::Customer.create!(
      customer_number: "LC-TEST-1",
      first_name: "Avery",
      last_name: "Reed",
      email: "avery@example.test",
      jurisdiction_code: "CA"
    )
  end
  let!(:vehicle) do
    CustomerAccounts::Vehicle.create!(
      customer: customer,
      vin: "5LV00000000000001",
      model: "Air Touring",
      model_year: 2025,
      weight_lbs: 4_200,
      purchase_price_cents: 4_899_000,
      powertrain: "bev",
      financing: "cash",
      usage: "personal",
      delivery_date: Date.new(2025, 6, 10)
    )
  end
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  it "issues a California tag" do
    post "/api/v1/temp_tags", params: { vin: vehicle.vin, issue_date: "2025-06-10" }.to_json, headers: headers

    expect(response).to have_http_status(:created)
    expect(response.parsed_body.dig("data", "jurisdiction")).to eq("CA")
    expect(response.parsed_body.dig("data", "valid_days")).to eq(90)
  end

  it "returns not found for an unknown VIN" do
    post "/api/v1/temp_tags", params: { vin: "5LV00000000000099", issue_date: "2025-06-10" }.to_json, headers: headers

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig("error", "code")).to eq("not_found")
  end

  it "rejects an invalid issue date" do
    post "/api/v1/temp_tags", params: { vin: vehicle.vin, issue_date: "2025-02-30" }.to_json, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "code")).to eq("validation_failed")
  end
end
