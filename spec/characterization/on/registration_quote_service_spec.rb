require "rails_helper"

RSpec.describe RegistrationQuoteService, "Ontario characterization" do
  let(:base_params) do
    {
      state: "ON",
      vehicle_weight_lbs: 4_200,
      vehicle_price_usd: 48_990,
      financed: true,
      buyer_state: "ON",
      delivery_date: "2025-06-10"
    }
  end

  let(:default_body) do
    {
      registration_fee_cents: 174_341,
      ev_surcharge_cents: 5_000,
      temp_tag_valid_days: 40,
      temp_tag_expires_on: "2025-07-20",
      lien_filing_required: true,
      lien_filing_method: "electronic",
      total_cents: 179_341
    }
  end

  def call(**overrides)
    described_class.call(base_params.merge(overrides))
  end

  it "returns the unwrapped compatibility body for Ontario" do
    result = call
    expect(result.status).to eq(:ok)
    expect(result.body).to eq(default_body)
  end

  it "accepts string-keyed params" do
    expect(described_class.call(base_params.stringify_keys).body).to eq(default_body)
  end

  describe "state normalization" do
    it "strips and upcases the state" do
      expect(call(state: " on ").body).to eq(default_body)
    end

    it "rejects the province name" do
      expect(call(state: "Ontario").to_h).to eq(status: :unprocessable_entity, body: { error: "Unknown jurisdiction: ONTARIO" })
    end

    it "rejects a blank state" do
      expect(call(state: "").body).to eq(error: "Unknown jurisdiction: (blank)")
    end
  end

  describe "fixed inputs" do
    it "builds the QuoteInput with bev, personal usage, ELT lienholder and no county" do
      expect(Jurisdictions::Ontario).to receive(:registration_fee_cents).and_wrap_original do |original, input|
        expect(input).to have_attributes(
          jurisdiction: "ON", weight_lbs: 4_200, purchase_price_cents: 4_899_000, powertrain: "bev",
          financing: "loan", lienholder_elt: true, buyer_jurisdiction: "ON", county: nil, usage: "personal",
          delivery_date: Date.new(2025, 6, 10)
        )
        original.call(input)
      end
      call
    end

    it "ignores powertrain, usage, financing, county and lienholder_elt params" do
      body = call(powertrain: "ice", usage: "commercial", financing: "lease", county: "york", lienholder_elt: false).body
      expect(body).to eq(default_body)
    end

    it "ignores buyer_state" do
      expect(call(buyer_state: "CA").body).to eq(default_body)
      expect(call(buyer_state: nil).body).to eq(default_body)
    end

    it "computes total_cents as registration plus EV surcharge" do
      body = call.body
      expect(body[:total_cents]).to eq(body[:registration_fee_cents] + body[:ev_surcharge_cents])
    end
  end

  describe "financed flag" do
    {
      true => [true, "electronic"],
      "true" => [true, "electronic"],
      "1" => [true, "electronic"],
      1 => [true, "electronic"],
      "t" => [true, "electronic"],
      "yes" => [true, "electronic"],
      "no" => [true, "electronic"],
      "on" => [true, "electronic"],
      false => [false, nil],
      "false" => [false, nil],
      "0" => [false, nil],
      0 => [false, nil],
      "f" => [false, nil],
      "off" => [false, nil],
      "" => [false, nil],
      nil => [false, nil]
    }.each do |financed, (required, method)|
      it "maps financed=#{financed.inspect} to required=#{required}, method=#{method.inspect}" do
        body = call(financed: financed).body
        expect(body[:lien_filing_required]).to be(required)
        expect(body[:lien_filing_method]).to eq(method)
        expect(body.except(:lien_filing_required, :lien_filing_method)).to eq(default_body.except(:lien_filing_required, :lien_filing_method))
      end
    end
  end

  describe "vehicle weight" do
    { 1 => 171_241, 3_299 => 171_241, 3_300 => 174_341, 5_499 => 174_341, 5_500 => 177_341, "3300" => 174_341, "4200.5" => 174_341, 4_200.5 => 174_341 }.each do |weight, registration|
      it "returns registration_fee_cents #{registration} for #{weight.inspect}" do
        body = call(vehicle_weight_lbs: weight).body
        expect(body[:registration_fee_cents]).to eq(registration)
        expect(body[:total_cents]).to eq(registration + 5_000)
      end
    end

    {
      0 => ["Vehicle weight lbs must be greater than 0"],
      -1 => ["Vehicle weight lbs must be greater than 0"],
      "abc" => ["Vehicle weight lbs must be greater than 0"],
      nil => ["Vehicle weight lbs can't be blank", "Vehicle weight lbs is not a number"]
    }.each do |weight, details|
      it "rejects #{weight.inspect}" do
        expect(call(vehicle_weight_lbs: weight).to_h).to eq(status: :unprocessable_entity, body: { error: "Invalid request", details: details })
      end
    end
  end

  describe "vehicle price (USD dollars, converted to cents with half-up rounding, then x1.35 FX for RST)" do
    {
      0 => 9_000,
      "0" => 9_000,
      "0.144" => 9_000,
      "0.145" => 9_001,
      0.15 => 9_001,
      2.96 => 9_010,
      4 => 9_014,
      "4.00" => 9_014,
      11 => 9_037,
      12 => 9_040,
      "1e3" => 12_375,
      48_990 => 174_341,
      "48990.005" => 174_341
    }.each do |price, registration|
      it "returns registration_fee_cents #{registration} for #{price.inspect}" do
        body = call(vehicle_price_usd: price).body
        expect(body[:registration_fee_cents]).to eq(registration)
        expect(body[:ev_surcharge_cents]).to eq(5_000)
        expect(body[:total_cents]).to eq(registration + 5_000)
      end
    end

    {
      "-1" => ["Vehicle price usd must be greater than or equal to 0"],
      "0x10" => ["Vehicle price usd is not a number"],
      "abc" => ["Vehicle price usd is not a number"],
      nil => ["Vehicle price usd can't be blank", "Vehicle price usd is not a number"]
    }.each do |price, details|
      it "rejects #{price.inspect}" do
        expect(call(vehicle_price_usd: price).to_h).to eq(status: :unprocessable_entity, body: { error: "Invalid request", details: details })
      end
    end
  end

  describe "delivery date" do
    {
      "2025-06-10" => "2025-07-20",
      "2024-02-20" => "2024-03-31",
      "2024-12-25" => "2025-02-03",
      "2025-6-1" => "2025-07-11",
      "20250610" => "2025-07-20",
      "June 10 2025" => "2025-07-20",
      "06/10/2025" => "2025-11-15"
    }.each do |delivery_date, expires_on|
      it "expires a tag delivered #{delivery_date.inspect} on #{expires_on}" do
        body = call(delivery_date: delivery_date).body
        expect(body[:temp_tag_valid_days]).to eq(40)
        expect(body[:temp_tag_expires_on]).to eq(expires_on)
      end
    end

    ["2025-02-30", "", nil].each do |delivery_date|
      it "rejects #{delivery_date.inspect}" do
        expect(call(delivery_date: delivery_date).to_h).to eq(
          status: :unprocessable_entity,
          body: { error: "Invalid request", details: ["Delivery date must be a valid YYYY-MM-DD date"] }
        )
      end
    end
  end
end
