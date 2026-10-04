require "rails_helper"

RSpec.describe "API v1 registration quotes", type: :request do
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }
  let(:payload) do
    {
      jurisdiction: "CA",
      weight_lbs: 4_200,
      purchase_price_cents: 4_899_000,
      delivery_date: "2025-06-10",
      financing: "loan"
    }
  end

  it "returns a California quote with request metadata" do
    post "/api/v1/registration_quotes", params: payload.to_json, headers: headers

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "total_cents")).to eq(18_500)
    expect(response.parsed_body.dig("data", "currency")).to eq("USD")
    expect(response.parsed_body.dig("meta", "request_id")).to be_present
  end

  it "rejects string integer values" do
    post "/api/v1/registration_quotes", params: payload.merge(weight_lbs: "4200").to_json, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "code")).to eq("validation_failed")
    expect(response.parsed_body.dig("error", "details", 0, "field")).to eq("weight_lbs")
  end

  it "reports malformed JSON" do
    post "/api/v1/registration_quotes", params: "{", headers: headers

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body.dig("error", "code")).to eq("malformed_json")
  end
end
