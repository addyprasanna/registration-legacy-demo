require "rails_helper"

RSpec.describe "Florida through the HTTP endpoints", type: :request do
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  describe "POST /api/v1/registration_quotes" do
    def post_quote(**overrides)
      payload = { jurisdiction: "FL", weight_lbs: 3_500, purchase_price_cents: 4_899_000, delivery_date: "2025-06-10" }.merge(overrides)
      post "/api/v1/registration_quotes", params: payload.to_json, headers: headers
      response.parsed_body["data"]
    end

    it "returns the Florida quote envelope" do
      expect(post_quote(jurisdiction: " fl ")).to eq(
        "jurisdiction" => "FL",
        "jurisdiction_name" => "Florida",
        "currency" => "USD",
        "line_items" => [
          { "code" => "registration", "label" => "Registration", "amount_cents" => 4_685 },
          { "code" => "weight_fee", "label" => "Weight fee", "amount_cents" => 4_725 }
        ],
        "registration_fee_cents" => 9_410,
        "ev_surcharge_cents" => 0,
        "total_cents" => 9_410,
        "temp_tag" => { "valid_days" => 30, "expires_on" => "2025-07-09" },
        "lien" => { "required" => false, "filing_method" => nil, "reason" => "No lien to record" }
      )
    end

    it "files a refinance on paper for a non-ELT lienholder" do
      expect(post_quote(financing: "refinance", lienholder_elt: false)["lien"]).to eq(
        "required" => true, "filing_method" => "paper", "reason" => "Paper filing with Florida motor vehicle agency"
      )
    end

    it "records no lien for a financed out-of-state buyer" do
      expect(post_quote(financing: "loan", buyer_jurisdiction: "ga")["lien"]).to eq(
        "required" => false, "filing_method" => nil, "reason" => "No lien to record"
      )
    end
  end

  describe "POST /api/v1/lien_determinations" do
    it "determines an electronic Florida loan filing" do
      post "/api/v1/lien_determinations", params: { jurisdiction: "FL", financing: "loan" }.to_json, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to eq(
        "jurisdiction" => "FL",
        "financing" => "loan",
        "lien_filing_required" => true,
        "filing_method" => "electronic",
        "elt_available" => true,
        "reason" => "Electronic filing via Florida ELT"
      )
    end

    it "records no lien for a Florida lease" do
      post "/api/v1/lien_determinations", params: { jurisdiction: "FL", financing: "lease", lienholder_elt: false }.to_json, headers: headers

      expect(response.parsed_body["data"]).to include("lien_filing_required" => false, "filing_method" => nil, "reason" => "No lien to record")
    end
  end

  describe "POST /api/v1/temp_tags" do
    before do
      customer = CustomerAccounts::Customer.create!(
        customer_number: "LC-FLCHAR-API",
        first_name: "Jordan",
        last_name: "Vale",
        email: "jordan.flchar@example.test",
        jurisdiction_code: "FL"
      )
      CustomerAccounts::Vehicle.create!(
        customer: customer,
        vin: "5LVFLCHAR00000002",
        model: "Air Pure",
        model_year: 2025,
        weight_lbs: 4_200,
        purchase_price_cents: 4_899_000,
        powertrain: "bev",
        financing: "cash",
        usage: "personal",
        delivery_date: Date.new(2025, 6, 10)
      )
    end

    it "issues a 30-day Florida tag for an out-of-state buyer" do
      post "/api/v1/temp_tags", params: { vin: "5LVFLCHAR00000002", issue_date: "2025-01-31", buyer_jurisdiction: "TX" }.to_json, headers: headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["data"]).to include(
        "jurisdiction" => "FL", "issued_on" => "2025-01-31", "valid_days" => 30, "expires_on" => "2025-03-01"
      )
    end
  end

  describe "POST /registration_quotes" do
    before { GoRouting::Route.find_or_initialize_by(jurisdiction_code: "FL").update!(mode: "legacy") }

    it "returns the legacy Florida compatibility body" do
      post "/registration_quotes", params: {
        state: "fl", vehicle_weight_lbs: 2_499, vehicle_price_usd: 48_990, financed: true, buyer_state: "FL", delivery_date: "2024-01-31"
      }.to_json, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        "registration_fee_cents" => 6_134,
        "ev_surcharge_cents" => 0,
        "temp_tag_valid_days" => 30,
        "temp_tag_expires_on" => "2024-02-29",
        "lien_filing_required" => true,
        "lien_filing_method" => "electronic",
        "total_cents" => 6_134
      )
    end
  end
end
