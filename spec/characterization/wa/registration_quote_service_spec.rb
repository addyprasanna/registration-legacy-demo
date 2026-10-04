require "rails_helper"

RSpec.describe RegistrationQuoteService, "Washington characterization" do
  let(:payload) do
    {
      state: "WA",
      vehicle_weight_lbs: 4_200,
      vehicle_price_usd: 48_990,
      financed: true,
      buyer_state: "WA",
      delivery_date: "2025-06-10"
    }
  end

  let(:default_body) do
    {
      registration_fee_cents: 5_850,
      ev_surcharge_cents: 15_000,
      temp_tag_valid_days: 45,
      temp_tag_expires_on: "2025-07-25",
      lien_filing_required: true,
      lien_filing_method: "electronic",
      total_cents: 20_850
    }
  end

  def quote(**overrides)
    described_class.call(payload.merge(overrides))
  end

  def captured_input(**overrides)
    captured = nil
    allow(Jurisdictions::Washington).to receive(:registration_fee_cents).and_wrap_original do |original, input|
      captured = input
      original.call(input)
    end
    result = quote(**overrides)
    expect(result.status).to eq(:ok)
    captured
  end

  it "returns the Washington quote in the compatibility response shape" do
    result = quote
    expect(result.status).to eq(:ok)
    expect(result.body).to eq(default_body)
  end

  it "accepts string keys" do
    expect(described_class.call(payload.stringify_keys).body).to eq(default_body)
  end

  it "normalizes the state code" do
    expect(quote(state: " wa ").body).to eq(default_body)
    expect(quote(state: "wa").body).to eq(default_body)
  end

  describe "QuoteInput built for the rule class" do
    it "fixes powertrain, county, usage and lienholder_elt regardless of request" do
      input = captured_input(powertrain: "ice", county: "KING", usage: "commercial", lienholder_elt: false)
      expect(input.jurisdiction).to eq("WA")
      expect(input.weight_lbs).to eq(4_200)
      expect(input.purchase_price_cents).to eq(4_899_000)
      expect(input.powertrain).to eq("bev")
      expect(input.county).to be_nil
      expect(input.usage).to eq("personal")
      expect(input.lienholder_elt).to be(true)
      expect(input.financing).to eq("loan")
      expect(input.buyer_jurisdiction).to eq("WA")
      expect(input.delivery_date).to eq(Date.new(2025, 6, 10))
    end

    it "never applies RTA tax because county is always nil" do
      result = quote(county: "KING", vehicle_price_usd: 1_000_000)
      expect(result.body).to eq(default_body)
    end

    it "ignores extra powertrain, usage and county params in the response" do
      expect(quote(powertrain: "ice", usage: "commercial", county: "PIERCE").body).to eq(default_body)
    end

    {
      true => "loan",
      "true" => "loan",
      "1" => "loan",
      "yes" => "loan",
      "no" => "loan",
      false => "cash",
      "false" => "cash",
      "0" => "cash",
      "" => "cash",
      nil => "cash"
    }.each do |financed, financing|
      it "maps financed #{financed.inspect} to financing #{financing.inspect}" do
        expect(captured_input(financed: financed).financing).to eq(financing)
      end
    end

    it "defaults financed to false (cash) when omitted" do
      captured = nil
      allow(Jurisdictions::Washington).to receive(:registration_fee_cents).and_wrap_original do |original, input|
        captured = input
        original.call(input)
      end
      result = described_class.call(payload.except(:financed))
      expect(captured.financing).to eq("cash")
      expect(result.body).to eq(default_body.merge(lien_filing_required: false, lien_filing_method: nil))
    end

    {
      48_990 => 4_899_000,
      48_990.5 => 4_899_050,
      "48990.005" => 4_899_001,
      "48990.004" => 4_899_000,
      "48990.015" => 4_899_002,
      "1e3" => 100_000,
      " 100 " => 10_000,
      "1_000" => 100_000,
      0 => 0,
      "0.004" => 0,
      "0.005" => 1
    }.each do |price, cents|
      it "converts vehicle_price_usd #{price.inspect} to #{cents} purchase_price_cents (half-up)" do
        expect(captured_input(vehicle_price_usd: price).purchase_price_cents).to eq(cents)
      end
    end

    {
      4_000 => 4_000,
      "4000" => 4_000,
      "3999.0" => 3_999,
      4_000.0 => 4_000,
      4_000.5 => 4_000
    }.each do |weight, cast|
      it "casts vehicle_weight_lbs #{weight.inspect} to #{cast}" do
        expect(captured_input(vehicle_weight_lbs: weight).weight_lbs).to eq(cast)
      end
    end

    it "passes the normalized buyer state, which does not change Washington results" do
      input = captured_input(buyer_state: " or ")
      expect(input.buyer_jurisdiction).to eq("OR")
      expect(quote(buyer_state: "OR").body).to eq(default_body)
    end

    it "falls back to the state when buyer_state is blank" do
      expect(captured_input(buyer_state: "").buyer_jurisdiction).to eq("WA")
      expect(captured_input(buyer_state: nil).buyer_jurisdiction).to eq("WA")
    end
  end

  describe "weight tiers" do
    {
      1 => 4_500,
      3_999 => 4_500,
      4_000 => 5_850,
      4_999 => 5_850,
      5_000 => 7_300,
      6_499 => 7_300,
      6_500 => 9_600,
      "3999.0" => 4_500,
      4_000.5 => 5_850
    }.each do |weight, fee|
      it "returns registration_fee_cents #{fee} for vehicle_weight_lbs #{weight.inspect}" do
        expect(quote(vehicle_weight_lbs: weight).body).to eq(
          default_body.merge(registration_fee_cents: fee, total_cents: fee + 15_000)
        )
      end
    end
  end

  it "does not vary any field with purchase price" do
    [0, 1, 48_990, 1_000_000, "48990.005"].each do |price|
      expect(quote(vehicle_price_usd: price).body).to eq(default_body)
    end
  end

  describe "financing" do
    it "files electronically when financed" do
      expect(quote(financed: true).body.values_at(:lien_filing_required, :lien_filing_method)).to eq([true, "electronic"])
    end

    it "does not file when not financed" do
      expect(quote(financed: false).body).to eq(default_body.merge(lien_filing_required: false, lien_filing_method: nil))
    end

    it "treats the string \"no\" as financed" do
      expect(quote(financed: "no").body.values_at(:lien_filing_required, :lien_filing_method)).to eq([true, "electronic"])
    end

    it "cannot express lease, refinance or paper filing" do
      expect(quote(financed: "lease").body.values_at(:lien_filing_required, :lien_filing_method)).to eq([true, "electronic"])
      expect(quote(financing: "lease", lienholder_elt: false, financed: false).body.values_at(:lien_filing_required, :lien_filing_method)).to eq([false, nil])
    end
  end

  describe "delivery date and temp tag expiry" do
    {
      "2025-06-10" => "2025-07-25",
      "2024-01-15" => "2024-02-29",
      "2024-02-28" => "2024-04-13",
      "2025-12-31" => "2026-02-14",
      "20250610" => "2025-07-25",
      "2025-6-1" => "2025-07-16",
      "06/10/2025" => "2025-11-20"
    }.each do |delivery_date, expires_on|
      it "expires #{expires_on} for delivery_date #{delivery_date.inspect}" do
        expect(quote(delivery_date: delivery_date).body).to eq(default_body.merge(temp_tag_expires_on: expires_on))
      end
    end

    it "parses a slash date as day/month/year" do
      expect(captured_input(delivery_date: "06/10/2025").delivery_date).to eq(Date.new(2025, 10, 6))
    end
  end

  describe "validation errors" do
    def invalid(details)
      [:unprocessable_entity, { error: "Invalid request", details: details }]
    end

    def outcome(**overrides)
      result = quote(**overrides)
      [result.status, result.body]
    end

    it "rejects zero, negative, blank and non-numeric weights" do
      expect(outcome(vehicle_weight_lbs: 0)).to eq(invalid(["Vehicle weight lbs must be greater than 0"]))
      expect(outcome(vehicle_weight_lbs: -1)).to eq(invalid(["Vehicle weight lbs must be greater than 0"]))
      expect(outcome(vehicle_weight_lbs: "abc")).to eq(invalid(["Vehicle weight lbs must be greater than 0"]))
      expect(outcome(vehicle_weight_lbs: nil)).to eq(invalid(["Vehicle weight lbs can't be blank", "Vehicle weight lbs is not a number"]))
    end

    it "rejects negative, blank, non-numeric and hexadecimal prices" do
      expect(outcome(vehicle_price_usd: -1)).to eq(invalid(["Vehicle price usd must be greater than or equal to 0"]))
      expect(outcome(vehicle_price_usd: "abc")).to eq(invalid(["Vehicle price usd is not a number"]))
      expect(outcome(vehicle_price_usd: "0x10")).to eq(invalid(["Vehicle price usd is not a number"]))
      expect(outcome(vehicle_price_usd: "0X1f")).to eq(invalid(["Vehicle price usd is not a number"]))
      expect(outcome(vehicle_price_usd: nil)).to eq(invalid(["Vehicle price usd can't be blank", "Vehicle price usd is not a number"]))
    end

    it "rejects missing or invalid delivery dates" do
      expect(outcome(delivery_date: nil)).to eq(invalid(["Delivery date must be a valid YYYY-MM-DD date"]))
      expect(outcome(delivery_date: "2025-13-01")).to eq(invalid(["Delivery date must be a valid YYYY-MM-DD date"]))
      expect(outcome(delivery_date: "2025-02-30")).to eq(invalid(["Delivery date must be a valid YYYY-MM-DD date"]))
    end
  end
end
