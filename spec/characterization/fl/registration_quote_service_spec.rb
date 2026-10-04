require "rails_helper"

RSpec.describe RegistrationQuoteService, "for Florida" do
  def params(**overrides)
    {
      state: "FL",
      vehicle_weight_lbs: 4_200,
      vehicle_price_usd: "48990.00",
      delivery_date: "2025-06-10"
    }.merge(overrides)
  end

  def quote(**overrides)
    described_class.call(params(**overrides))
  end

  def body(**overrides)
    result = quote(**overrides)
    expect(result.status).to eq(:ok)
    result.body
  end

  let(:base_body) do
    {
      registration_fee_cents: 10_355,
      ev_surcharge_cents: 0,
      temp_tag_valid_days: 30,
      temp_tag_expires_on: "2025-07-09",
      lien_filing_required: false,
      lien_filing_method: nil,
      total_cents: 10_355
    }
  end

  it "returns the full compatibility body for a cash in-state quote" do
    result = quote
    expect(result.status).to eq(:ok)
    expect(result.body).to eq(base_body)
  end

  it "normalizes state case and whitespace" do
    expect(body(state: "fl")).to eq(base_body)
    expect(body(state: " fl ")).to eq(base_body)
  end

  it "passes only the documented input fields to the rule" do
    expect(body(powertrain: "ice", financing: "lease", usage: "commercial", county: "MIAMI-DADE", lienholder_elt: false))
      .to eq(base_body)
  end

  describe "weight" do
    {
      1 => 2_761,
      2_499 => 6_134,
      2_500 => 7_410,
      3_499 => 8_759,
      3_500 => 9_410,
      4_999 => 11_434,
      5_000 => 13_990,
      20_000 => 34_240
    }.each do |weight, total|
      it "charges #{total} cents at #{weight} lbs" do
        expect(body(vehicle_weight_lbs: weight)).to include(registration_fee_cents: total, ev_surcharge_cents: 0, total_cents: total)
      end
    end

    it "accepts string weights and truncates fractional strings" do
      expect(body(vehicle_weight_lbs: "2499")).to include(total_cents: 6_134)
      expect(body(vehicle_weight_lbs: "2499.7")).to include(total_cents: 6_134)
    end

    it "casts a comma-grouped weight string to its leading digits" do
      expect(body(vehicle_weight_lbs: "2,499")).to include(registration_fee_cents: 2_763, total_cents: 2_763)
    end

    it "rejects zero, hex strings that cast to zero, and negatives" do
      [0, "0x9c3", -1].each do |weight|
        expect(quote(vehicle_weight_lbs: weight).to_h).to eq(
          status: :unprocessable_entity,
          body: { error: "Invalid request", details: ["Vehicle weight lbs must be greater than 0"] }
        )
      end
    end
  end

  describe "price" do
    it "does not affect any Florida output across price thresholds" do
      [0, "0", "0.004", "0.005", "1", "48990.005", "99999999.99", 1_000_000_000].each do |price|
        expect(body(vehicle_price_usd: price)).to eq(base_body)
      end
    end

    it "rejects negative, non-numeric and hex prices" do
      expect(quote(vehicle_price_usd: "-0.01").body).to eq(error: "Invalid request", details: ["Vehicle price usd must be greater than or equal to 0"])
      expect(quote(vehicle_price_usd: "abc").body).to eq(error: "Invalid request", details: ["Vehicle price usd is not a number"])
      expect(quote(vehicle_price_usd: "0x10").body).to eq(error: "Invalid request", details: ["Vehicle price usd is not a number"])
      expect(quote(vehicle_price_usd: nil).body).to eq(
        error: "Invalid request", details: ["Vehicle price usd can't be blank", "Vehicle price usd is not a number"]
      )
    end
  end

  describe "financed" do
    it "maps truthy values to a loan filed electronically" do
      [true, "true", "1", "t", "yes", "no", 1].each do |financed|
        expect(body(financed: financed)).to eq(base_body.merge(lien_filing_required: true, lien_filing_method: "electronic"))
      end
    end

    it "maps false, falsy strings, blank and nil to cash" do
      [false, "false", "0", "f", "off", "", nil].each do |financed|
        expect(body(financed: financed)).to eq(base_body)
      end
    end

    it "never produces a paper filing because lienholder_elt is always true" do
      expect(body(financed: true, lienholder_elt: false)[:lien_filing_method]).to eq("electronic")
    end
  end

  describe "buyer_state" do
    it "defaults to state when omitted, nil or blank" do
      [{}, { buyer_state: nil }, { buyer_state: "" }, { buyer_state: "  " }].each do |extra|
        expect(body(financed: true, **extra)).to include(lien_filing_required: true, lien_filing_method: "electronic")
      end
    end

    it "normalizes case and whitespace" do
      expect(body(financed: true, buyer_state: " fl ")).to include(lien_filing_required: true, lien_filing_method: "electronic")
    end

    it "records no lien for an out-of-state buyer, including unregistered codes" do
      %w[GA ga CA ZZ].each do |buyer|
        expect(body(financed: true, buyer_state: buyer)).to eq(base_body)
      end
    end

    it "does not change fees or temp tag for an out-of-state buyer" do
      expect(body(buyer_state: "GA")).to eq(base_body)
    end
  end

  describe "delivery_date" do
    {
      "2025-06-10" => "2025-07-09",
      "2025-01-31" => "2025-03-01",
      "2024-01-31" => "2024-02-29",
      "2025-12-31" => "2026-01-29",
      "2025-6-1" => "2025-06-30",
      "06/10/2025" => "2025-11-04",
      "June 10 2025" => "2025-07-09"
    }.each do |delivery, expiry|
      it "returns expiry #{expiry} for delivery_date #{delivery.inspect}" do
        expect(body(delivery_date: delivery)).to include(temp_tag_valid_days: 30, temp_tag_expires_on: expiry)
      end
    end

    it "rejects impossible and missing dates" do
      ["2025-02-30", nil, ""].each do |delivery|
        expect(quote(delivery_date: delivery).body).to eq(
          error: "Invalid request", details: ["Delivery date must be a valid YYYY-MM-DD date"]
        )
      end
    end
  end
end
