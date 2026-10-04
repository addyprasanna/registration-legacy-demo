require "rails_helper"

RSpec.describe "POST /registration_quotes", type: :request do
  def post_quote(payload)
    post "/registration_quotes", params: payload.to_json, headers: { "CONTENT_TYPE" => "application/json" }
  end

  it "returns a California quote with the legacy response shape" do
    post_quote(
      state: "CA",
      vehicle_weight_lbs: 4_200,
      vehicle_price_usd: 48_990,
      financed: true,
      buyer_state: "CA",
      delivery_date: "2025-06-10"
    )

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(
      "registration_fee_cents" => 8_500,
      "ev_surcharge_cents" => 10_000,
      "temp_tag_valid_days" => 90,
      "temp_tag_expires_on" => "2025-09-08",
      "lien_filing_required" => true,
      "lien_filing_method" => "electronic",
      "total_cents" => 18_500
    )
  end
end
