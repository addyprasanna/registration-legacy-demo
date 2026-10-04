require "rails_helper"

RSpec.describe "API v1 lien determinations", type: :request do
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  it "determines an electronic California loan filing" do
    post "/api/v1/lien_determinations", params: { jurisdiction: "CA", financing: "loan", lienholder_elt: true }.to_json, headers: headers

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "lien_filing_required")).to be(true)
    expect(response.parsed_body.dig("data", "filing_method")).to eq("electronic")
  end

  it "returns no filing for a California cash purchase" do
    post "/api/v1/lien_determinations", params: { jurisdiction: "CA", financing: "cash" }.to_json, headers: headers

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "lien_filing_required")).to be(false)
  end

  it "rejects unsupported financing values" do
    post "/api/v1/lien_determinations", params: { jurisdiction: "CA", financing: "Loan" }.to_json, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "code")).to eq("validation_failed")
  end
end
