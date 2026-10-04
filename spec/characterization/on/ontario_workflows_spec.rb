require "rails_helper"

RSpec.describe "Ontario characterization through domain services and APIs", type: :request do
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  def create_vehicle(**attributes)
    customer = CustomerAccounts::Customer.create!(
      customer_number: "CHAR-ON-#{SecureRandom.hex(4)}",
      first_name: "Ontario",
      last_name: "Characterization",
      email: "char-on-#{SecureRandom.hex(4)}@example.test",
      jurisdiction_code: "ON"
    )
    CustomerAccounts::Vehicle.create!({
      customer: customer,
      vin: "9ZCHAR#{SecureRandom.random_number(10**11).to_s.rjust(11, '0')}",
      model: "Air Pure",
      model_year: 2025,
      weight_lbs: 5_499,
      purchase_price_cents: 1_200,
      powertrain: "phev",
      financing: "lease",
      lienholder_elt: false,
      usage: "commercial",
      delivery_date: Date.new(2024, 2, 20)
    }.merge(attributes))
  end

  describe Registrations::FeeCalculator do
    it "snapshots Ontario line items and totals from the vehicle" do
      result = described_class.call(vehicle: create_vehicle)

      expect(result.jurisdiction).to be(Jurisdictions::Ontario)
      expect(result.line_items.map(&:to_h)).to eq([
        { code: "registration", label: "Registration", amount_cents: 9_000 },
        { code: "rst", label: "Retail sales tax", amount_cents: 40 },
        { code: "ev_surcharge", label: "EV surcharge", amount_cents: 2_500 }
      ])
      expect(result.registration_fee_cents).to eq(9_040)
      expect(result.ev_surcharge_cents).to eq(2_500)
      expect(result.total_cents).to eq(11_540)
    end
  end

  describe Registrations::Registration do
    let(:vehicle) { create_vehicle }

    it "stamps CAD on save for jurisdiction code ON, overriding a supplied currency" do
      registration = described_class.create!(vehicle: vehicle, jurisdiction_code: "ON", currency: "USD")
      expect(registration.reload.currency).to eq("CAD")
    end

    it "stamps CAD when no currency is supplied" do
      registration = described_class.create!(vehicle: vehicle, jurisdiction_code: "ON")
      expect(registration.reload.currency).to eq("CAD")
    end

    it "does not stamp a lowercase on code" do
      registration = described_class.create!(vehicle: vehicle, jurisdiction_code: "on", currency: "USD")
      expect(registration.reload.currency).to eq("USD")
    end
  end

  describe TempTags::IssueService do
    it "issues a 10-day commercial tag" do
      tag = described_class.call(vehicle: create_vehicle, issue_date: Date.new(2024, 2, 20))
      expect(tag).to have_attributes(jurisdiction_code: "ON", valid_days: 10, issued_on: Date.new(2024, 2, 20), expires_on: Date.new(2024, 3, 1))
      expect(tag.tag_number).to match(/\AON-T-\d{6}\z/)
    end

    it "issues a 40-day personal tag" do
      tag = described_class.call(vehicle: create_vehicle, issue_date: Date.new(2024, 2, 20), usage: "personal")
      expect(tag).to have_attributes(valid_days: 40, expires_on: Date.new(2024, 3, 31))
    end

    it "offsets the expiry by an explicit valid_days override" do
      tag = described_class.call(vehicle: create_vehicle, issue_date: Date.new(2024, 2, 20), usage: "personal", valid_days: 5)
      expect(tag).to have_attributes(valid_days: 5, expires_on: Date.new(2024, 2, 25))
    end
  end

  describe LienFilings::DeterminationService do
    it "returns an electronic lease filing even when the lienholder is not ELT" do
      result = described_class.call(Jurisdictions::QuoteInput.new(jurisdiction: "on", financing: "lease", lienholder_elt: false))
      expect(result.to_h.except(:input)).to eq(
        jurisdiction: Jurisdictions::Ontario,
        required: true,
        filing_method: "electronic",
        reason: "Electronic filing via Ontario ELT"
      )
    end
  end

  describe "POST /api/v1/registration_quotes" do
    let(:payload) do
      { jurisdiction: "ON", weight_lbs: 4_200, purchase_price_cents: 4_899_000, delivery_date: "2025-06-10", financing: "loan" }
    end

    it "returns the Ontario quote in CAD" do
      post "/api/v1/registration_quotes", params: payload.to_json, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to eq(
        "jurisdiction" => "ON",
        "jurisdiction_name" => "Ontario",
        "currency" => "CAD",
        "line_items" => [
          { "code" => "registration", "label" => "Registration", "amount_cents" => 9_000 },
          { "code" => "rst", "label" => "Retail sales tax", "amount_cents" => 165_341 },
          { "code" => "ev_surcharge", "label" => "EV surcharge", "amount_cents" => 5_000 }
        ],
        "registration_fee_cents" => 174_341,
        "ev_surcharge_cents" => 5_000,
        "total_cents" => 179_341,
        "temp_tag" => { "valid_days" => 40, "expires_on" => "2025-07-20" },
        "lien" => { "required" => true, "filing_method" => "electronic", "reason" => "Electronic filing via Ontario ELT" }
      )
    end

    it "returns a commercial cash quote with no lien" do
      post "/api/v1/registration_quotes",
           params: payload.merge(jurisdiction: " on ", usage: "commercial", financing: "cash", powertrain: "ice", lienholder_elt: false).to_json,
           headers: headers

      data = response.parsed_body["data"]
      expect(data).to include("jurisdiction" => "ON", "currency" => "CAD", "registration_fee_cents" => 174_341, "ev_surcharge_cents" => 0, "total_cents" => 174_341)
      expect(data["temp_tag"]).to eq("valid_days" => 10, "expires_on" => "2025-06-20")
      expect(data["lien"]).to eq("required" => false, "filing_method" => nil, "reason" => "No lien to record")
    end
  end

  describe "POST /api/v1/lien_determinations" do
    %w[loan lease refinance].each do |financing|
      it "returns an electronic #{financing} filing with lienholder_elt false" do
        post "/api/v1/lien_determinations", params: { jurisdiction: "ON", financing: financing, lienholder_elt: false }.to_json, headers: headers

        expect(response.parsed_body["data"]).to eq(
          "jurisdiction" => "ON",
          "financing" => financing,
          "lien_filing_required" => true,
          "filing_method" => "electronic",
          "elt_available" => true,
          "reason" => "Electronic filing via Ontario ELT"
        )
      end
    end

    it "returns no filing for cash" do
      post "/api/v1/lien_determinations", params: { jurisdiction: "ON", financing: "cash" }.to_json, headers: headers

      expect(response.parsed_body["data"]).to include("lien_filing_required" => false, "filing_method" => nil, "reason" => "No lien to record")
    end
  end

  describe "POST /api/v1/temp_tags" do
    it "keeps the Ontario default days for an out-of-province buyer" do
      vehicle = create_vehicle(usage: "personal")
      post "/api/v1/temp_tags", params: { vin: vehicle.vin, issue_date: "2024-12-25", buyer_jurisdiction: "TX" }.to_json, headers: headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["data"]).to include("jurisdiction" => "ON", "issued_on" => "2024-12-25", "valid_days" => 40, "expires_on" => "2025-02-03")
    end

    it "issues a commercial 10-day tag" do
      vehicle = create_vehicle
      post "/api/v1/temp_tags", params: { vin: vehicle.vin, issue_date: "2024-12-22" }.to_json, headers: headers

      expect(response.parsed_body["data"]).to include("valid_days" => 10, "expires_on" => "2025-01-01")
    end
  end

  describe "POST /registration_quotes (compatibility, legacy mode)" do
    before { GoRouting::Route.find_or_initialize_by(jurisdiction_code: "ON").update!(mode: "legacy") }

    it "returns the unwrapped Ontario body" do
      post "/registration_quotes",
           params: { state: "on", vehicle_weight_lbs: 4_200, vehicle_price_usd: 48_990, financed: false, delivery_date: "2025-06-10", powertrain: "ice" }.to_json,
           headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        "registration_fee_cents" => 174_341,
        "ev_surcharge_cents" => 5_000,
        "temp_tag_valid_days" => 40,
        "temp_tag_expires_on" => "2025-07-20",
        "lien_filing_required" => false,
        "lien_filing_method" => nil,
        "total_cents" => 179_341
      )
    end
  end
end
