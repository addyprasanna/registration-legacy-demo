require "rails_helper"

RSpec.describe "Washington quote endpoints", type: :request do
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  describe "POST /api/v1/registration_quotes" do
    let(:payload) do
      { jurisdiction: "WA", weight_lbs: 4_200, purchase_price_cents: 4_899_000, delivery_date: "2025-06-10" }
    end

    def post_quote(overrides = {})
      post "/api/v1/registration_quotes", params: payload.merge(overrides).to_json, headers: headers
      response.parsed_body["data"]
    end

    it "returns RTA tax for an RTA county" do
      data = post_quote(county: "King", financing: "loan")
      expect(response).to have_http_status(:ok)
      expect(data).to eq(
        "jurisdiction" => "WA",
        "jurisdiction_name" => "Washington",
        "currency" => "USD",
        "line_items" => [
          { "code" => "registration", "label" => "Registration", "amount_cents" => 5_850 },
          { "code" => "rta_tax", "label" => "Regional transit tax", "amount_cents" => 53_889 },
          { "code" => "ev_surcharge", "label" => "EV surcharge", "amount_cents" => 15_000 }
        ],
        "registration_fee_cents" => 59_739,
        "ev_surcharge_cents" => 15_000,
        "total_cents" => 74_739,
        "temp_tag" => { "valid_days" => 45, "expires_on" => "2025-07-25" },
        "lien" => { "required" => true, "filing_method" => "electronic", "reason" => "Electronic filing via Washington ELT" }
      )
    end

    it "omits RTA tax for a non-RTA county" do
      data = post_quote(county: "Spokane")
      expect(data["line_items"].map { |item| item["code"] }).to eq(%w[registration ev_surcharge])
      expect(data["registration_fee_cents"]).to eq(5_850)
      expect(data["total_cents"]).to eq(20_850)
    end

    it "applies commercial validity, phev surcharge and paper lease filing" do
      data = post_quote(usage: "commercial", powertrain: "phev", financing: "lease", lienholder_elt: false, weight_lbs: 6_500)
      expect(data["registration_fee_cents"]).to eq(9_600)
      expect(data["ev_surcharge_cents"]).to eq(7_500)
      expect(data["total_cents"]).to eq(17_100)
      expect(data["temp_tag"]).to eq("valid_days" => 20, "expires_on" => "2025-06-30")
      expect(data["lien"]).to eq("required" => true, "filing_method" => "paper", "reason" => "Paper filing with Washington motor vehicle agency")
    end
  end

  describe "POST /registration_quotes (compatibility, legacy mode)" do
    before { GoRouting::Route.find_or_initialize_by(jurisdiction_code: "WA").update!(mode: "legacy") }

    it "returns the compatibility body for Washington" do
      post "/registration_quotes", params: {
        state: "wa", vehicle_weight_lbs: 4_000, vehicle_price_usd: 48_990, financed: true,
        buyer_state: "WA", delivery_date: "2025-06-10", county: "KING"
      }.to_json, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        "registration_fee_cents" => 5_850,
        "ev_surcharge_cents" => 15_000,
        "temp_tag_valid_days" => 45,
        "temp_tag_expires_on" => "2025-07-25",
        "lien_filing_required" => true,
        "lien_filing_method" => "electronic",
        "total_cents" => 20_850
      )
    end
  end
end
