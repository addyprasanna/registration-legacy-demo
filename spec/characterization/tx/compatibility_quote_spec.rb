require "rails_helper"

RSpec.describe RegistrationQuoteService, "for TX" do
  let(:base_params) do
    {
      state: "TX",
      vehicle_weight_lbs: 4_200,
      vehicle_price_usd: "48990.00",
      delivery_date: "2025-06-10"
    }
  end

  def quote(**overrides)
    described_class.call(base_params.merge(overrides))
  end

  def built_input(**overrides)
    inputs = []
    allow(Jurisdictions::QuoteInput).to receive(:new).and_wrap_original do |original, *args, **kwargs|
      original.call(*args, **kwargs).tap { |built| inputs << built }
    end
    result = quote(**overrides)
    expect(result.status).to eq(:ok)
    inputs.last
  end

  it "returns the unwrapped compatibility response" do
    result = quote

    expect(result.status).to eq(:ok)
    expect(result.body).to eq(
      registration_fee_cents: 6_250,
      ev_surcharge_cents: 20_000,
      temp_tag_valid_days: 60,
      temp_tag_expires_on: "2025-08-09",
      lien_filing_required: false,
      lien_filing_method: nil,
      total_cents: 26_250
    )
  end

  describe "inputs it fixes when building Jurisdictions::QuoteInput" do
    it "always uses bev, lienholder_elt true, no county, and personal usage" do
      input = built_input

      expect(input.jurisdiction).to eq("TX")
      expect(input.weight_lbs).to eq(4_200)
      expect(input.purchase_price_cents).to eq(4_899_000)
      expect(input.powertrain).to eq("bev")
      expect(input.financing).to eq("cash")
      expect(input.lienholder_elt).to be(true)
      expect(input.buyer_jurisdiction).to eq("TX")
      expect(input.county).to be_nil
      expect(input.usage).to eq("personal")
      expect(input.delivery_date).to eq(Date.new(2025, 6, 10))
    end

    it "ignores powertrain, county, usage, lienholder_elt, and financing type params" do
      result = quote(powertrain: "ice", county: "TRAVIS", usage: "commercial", lienholder_elt: false, financing: "lease")
      expect(result.body).to eq(quote.body)
    end

    it "maps financed to loan or cash" do
      expect(built_input(financed: true).financing).to eq("loan")
      expect(built_input(financed: false).financing).to eq("cash")
    end

    {
      "0.004" => 0,
      "0.005" => 1,
      "48990.004" => 4_899_000,
      "48990.005" => 4_899_001,
      "48990.015" => 4_899_002,
      "1e3" => 100_000,
      " 12.5 " => 1_250,
      12.345 => 1_235
    }.each do |usd, cents|
      it "converts vehicle_price_usd #{usd.inspect} to #{cents} cents, rounding half up" do
        expect(built_input(vehicle_price_usd: usd).purchase_price_cents).to eq(cents)
      end
    end

    it "uppercases and strips state and buyer_state" do
      input = built_input(state: " tx ", buyer_state: " ca ")
      expect(input.jurisdiction).to eq("TX")
      expect(input.buyer_jurisdiction).to eq("CA")
    end
  end

  describe "registration fees" do
    {
      1 => 5_075,
      4_000 => 5_075,
      "4000" => 5_075,
      "4000.9" => 5_075,
      4_000.5 => 5_075,
      "4,000" => 5_075,
      4_001 => 6_250,
      "5999.99" => 6_250,
      5_999 => 6_250,
      6_000 => 7_825,
      "6000" => 7_825,
      6_001 => 7_825
    }.each do |weight, fee|
      it "returns #{fee} for vehicle_weight_lbs #{weight.inspect}" do
        result = quote(vehicle_weight_lbs: weight)
        expect(result.status).to eq(:ok)
        expect(result.body[:registration_fee_cents]).to eq(fee)
        expect(result.body[:ev_surcharge_cents]).to eq(20_000)
        expect(result.body[:total_cents]).to eq(fee + 20_000)
      end
    end

    it "does not vary with vehicle price" do
      %w[0 0.01 25000 48990.00 100000 9999999.99].each do |price|
        expect(quote(vehicle_price_usd: price).body).to eq(quote.body)
      end
    end
  end

  describe "temporary tags" do
    it "uses 60 days when buyer_state is omitted, blank, or TX" do
      [nil, "", "   ", "TX", "tx", " Tx "].each do |buyer|
        body = quote(buyer_state: buyer).body
        expect(body[:temp_tag_valid_days]).to eq(60)
        expect(body[:temp_tag_expires_on]).to eq("2025-08-09")
      end
    end

    it "uses 30 days for any other buyer_state, including codes that are not registered" do
      %w[CA ca OK ON ZZ TEXAS].each do |buyer|
        body = quote(buyer_state: buyer).body
        expect(body[:temp_tag_valid_days]).to eq(30)
        expect(body[:temp_tag_expires_on]).to eq("2025-07-10")
      end
    end

    {
      ["2024-01-01", nil] => [60, "2024-03-01"],
      ["2024-01-31", "CA"] => [30, "2024-03-01"],
      ["2025-01-01", nil] => [60, "2025-03-02"],
      ["2025-01-01", "CA"] => [30, "2025-01-31"],
      ["2025-12-31", nil] => [60, "2026-03-01"],
      ["2025-12-31", "CA"] => [30, "2026-01-30"]
    }.each do |(date, buyer), (days, expires)|
      it "returns #{days} days expiring #{expires} for delivery #{date} and buyer_state #{buyer.inspect}" do
        body = quote(delivery_date: date, buyer_state: buyer).body
        expect(body[:temp_tag_valid_days]).to eq(days)
        expect(body[:temp_tag_expires_on]).to eq(expires)
      end
    end

    it "accepts non-ISO date strings that Date parsing understands" do
      expect(quote(delivery_date: "2025/06/10").body[:temp_tag_expires_on]).to eq("2025-08-09")
    end
  end

  describe "lien filing" do
    [true, "true", "1", 1, "t", "on", "yes", "no", "anything"].each do |value|
      it "requires electronic filing when financed is #{value.inspect}" do
        body = quote(financed: value).body
        expect(body[:lien_filing_required]).to be(true)
        expect(body[:lien_filing_method]).to eq("electronic")
      end
    end

    [false, "false", "0", 0, "f", "off", "FALSE", "", nil].each do |value|
      it "requires no filing when financed is #{value.inspect}" do
        body = quote(financed: value).body
        expect(body[:lien_filing_required]).to be(false)
        expect(body[:lien_filing_method]).to be_nil
      end
    end

    it "requires no filing when financed is omitted" do
      expect(described_class.call(base_params).body).to include(lien_filing_required: false, lien_filing_method: nil)
    end
  end

  describe "rejections" do
    {
      { state: "TEXAS" } => { error: "Unknown jurisdiction: TEXAS" },
      { state: "" } => { error: "Unknown jurisdiction: (blank)" },
      { vehicle_weight_lbs: 0 } => { error: "Invalid request", details: ["Vehicle weight lbs must be greater than 0"] },
      { vehicle_weight_lbs: -1 } => { error: "Invalid request", details: ["Vehicle weight lbs must be greater than 0"] },
      { vehicle_weight_lbs: nil } => { error: "Invalid request", details: ["Vehicle weight lbs can't be blank", "Vehicle weight lbs is not a number"] },
      { vehicle_price_usd: "-0.01" } => { error: "Invalid request", details: ["Vehicle price usd must be greater than or equal to 0"] },
      { vehicle_price_usd: "0x10" } => { error: "Invalid request", details: ["Vehicle price usd is not a number"] },
      { vehicle_price_usd: "" } => { error: "Invalid request", details: ["Vehicle price usd can't be blank", "Vehicle price usd is not a number"] },
      { delivery_date: "2025-02-30" } => { error: "Invalid request", details: ["Delivery date must be a valid YYYY-MM-DD date"] }
    }.each do |overrides, body|
      it "returns unprocessable_entity for #{overrides.inspect}" do
        result = quote(**overrides)
        expect(result.status).to eq(:unprocessable_entity)
        expect(result.body).to eq(body)
      end
    end
  end

  describe "RegistrationQuote#price_cents" do
    it "converts hexadecimal strings, although validation rejects them before the service uses them" do
      expect(RegistrationQuote.new(vehicle_price_usd: "0x10").price_cents).to eq(BigDecimal("1600"))
    end
  end
end
