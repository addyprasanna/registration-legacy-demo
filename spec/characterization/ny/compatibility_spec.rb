require "rails_helper"

RSpec.describe RegistrationQuoteService, "New York compatibility quotes (characterization)" do
  def payload(**overrides)
    {
      state: "NY",
      vehicle_weight_lbs: 4_000,
      vehicle_price_usd: 50_000,
      financed: false,
      buyer_state: "NY",
      delivery_date: "2025-06-10"
    }.merge(overrides)
  end

  def quote(**overrides)
    described_class.call(payload(**overrides))
  end

  def body(**overrides)
    result = quote(**overrides)
    expect(result.status).to eq(:ok)
    result.body
  end

  def baseline
    {
      registration_fee_cents: 27_680,
      ev_surcharge_cents: 7_500,
      temp_tag_valid_days: 30,
      temp_tag_expires_on: "2025-07-10",
      lien_filing_required: false,
      lien_filing_method: nil,
      total_cents: 35_180
    }
  end

  def captured_input(**overrides)
    captured = nil
    allow(Jurisdictions::NewYork).to receive(:registration_fee_cents).and_wrap_original do |original, input|
      captured = input
      original.call(input)
    end
    quote(**overrides)
    captured
  end

  it "returns the unwrapped response for a default NY request" do
    expect(quote.status).to eq(:ok)
    expect(quote.body).to eq(baseline)
  end

  describe "QuoteInput built for the rule" do
    it "fixes powertrain, lienholder ELT, county, and usage, and maps the remaining fields" do
      input = captured_input
      expect(input).to be_a(Jurisdictions::QuoteInput)
      expect(input.attributes).to eq(
        "jurisdiction" => "NY",
        "weight_lbs" => 4_000,
        "purchase_price_cents" => 5_000_000,
        "powertrain" => "bev",
        "financing" => "cash",
        "lienholder_elt" => true,
        "buyer_jurisdiction" => "NY",
        "county" => nil,
        "usage" => "personal",
        "delivery_date" => Date.new(2025, 6, 10)
      )
    end

    it "maps financed true to loan" do
      expect(captured_input(financed: true).financing).to eq("loan")
    end

    it "normalizes the buyer state" do
      expect(captured_input(buyer_state: " nj ").buyer_jurisdiction).to eq("NJ")
      expect(captured_input(buyer_state: nil).buyer_jurisdiction).to eq("NY")
    end

    it "ignores QuoteInput-only fields passed as params" do
      input = captured_input(county: "KINGS", powertrain: "ice", usage: "commercial", lienholder_elt: false, financing: "refinance")
      expect(input.county).to be_nil
      expect(input.powertrain).to eq("bev")
      expect(input.usage).to eq("personal")
      expect(input.lienholder_elt).to be(true)
      expect(input.financing).to eq("cash")
      expect(body(county: "KINGS", powertrain: "ice", usage: "commercial", lienholder_elt: false, financing: "refinance")).to eq(baseline)
    end
  end

  describe "state" do
    ["ny", " Ny ", "NY"].each do |state|
      it "accepts #{state.inspect}" do
        expect(body(state: state)).to eq(baseline)
      end
    end

    it "rejects unknown and blank states" do
      expect(quote(state: "NYC").to_h).to eq(status: :unprocessable_entity, body: { error: "Unknown jurisdiction: NYC" })
      expect(quote(state: nil).to_h).to eq(status: :unprocessable_entity, body: { error: "Unknown jurisdiction: (blank)" })
      expect(quote(state: " ").to_h).to eq(status: :unprocessable_entity, body: { error: "Unknown jurisdiction: (blank)" })
    end
  end

  describe "vehicle weight" do
    {
      1 => 25_750,
      3_499 => 25_750,
      3_500 => 27_680,
      5_499 => 27_680,
      5_500 => 30_225,
      20_000 => 30_225,
      "3499" => 25_750,
      "3499.9" => 25_750,
      3_499.9 => 25_750,
      "3500" => 27_680
    }.each do |weight, fee|
      it "returns registration_fee_cents #{fee} for #{weight.inspect}" do
        expect(body(vehicle_weight_lbs: weight)).to include(registration_fee_cents: fee, total_cents: fee + 7_500)
      end
    end

    [0, -5, "0.5", "abc"].each do |weight|
      it "rejects #{weight.inspect}" do
        expect(quote(vehicle_weight_lbs: weight).to_h).to eq(
          status: :unprocessable_entity,
          body: { error: "Invalid request", details: ["Vehicle weight lbs must be greater than 0"] }
        )
      end
    end

    it "rejects a missing weight" do
      expect(quote(vehicle_weight_lbs: nil).to_h).to eq(
        status: :unprocessable_entity,
        body: { error: "Invalid request", details: ["Vehicle weight lbs can't be blank", "Vehicle weight lbs is not a number"] }
      )
    end
  end

  describe "vehicle price" do
    {
      0 => 5_180,
      1.11 => 5_180,
      1.12 => 5_181,
      "1.114" => 5_180,
      "1.115" => 5_181,
      "0.001" => 5_180,
      "1234.555" => 5_736,
      " 50000 " => 27_680,
      "1e3" => 5_630,
      50_000.005 => 27_680
    }.each do |price, fee|
      it "returns registration_fee_cents #{fee} for #{price.inspect}" do
        expect(body(vehicle_price_usd: price)).to include(registration_fee_cents: fee, total_cents: fee + 7_500)
      end
    end

    it "rounds the dollar price to cents half-up before building the input" do
      expect(captured_input(vehicle_price_usd: "1.115").purchase_price_cents).to eq(112)
      expect(captured_input(vehicle_price_usd: "1.114").purchase_price_cents).to eq(111)
      expect(captured_input(vehicle_price_usd: "1234.555").purchase_price_cents).to eq(123_456)
    end

    ["0x10", "0x1F", "abc"].each do |price|
      it "rejects #{price.inspect} as not a number" do
        expect(quote(vehicle_price_usd: price).to_h).to eq(
          status: :unprocessable_entity,
          body: { error: "Invalid request", details: ["Vehicle price usd is not a number"] }
        )
      end
    end

    it "rejects negative and missing prices" do
      expect(quote(vehicle_price_usd: -1).to_h).to eq(
        status: :unprocessable_entity,
        body: { error: "Invalid request", details: ["Vehicle price usd must be greater than or equal to 0"] }
      )
      expect(quote(vehicle_price_usd: nil).to_h).to eq(
        status: :unprocessable_entity,
        body: { error: "Invalid request", details: ["Vehicle price usd can't be blank", "Vehicle price usd is not a number"] }
      )
    end
  end

  describe "financed" do
    [true, "true", 1, "1", "yes", "no"].each do |financed|
      it "files an electronic lien for #{financed.inspect}" do
        expect(body(financed: financed)).to eq(baseline.merge(lien_filing_required: true, lien_filing_method: "electronic"))
      end
    end

    [false, "false", "0", "off", "", nil].each do |financed|
      it "files no lien for #{financed.inspect}" do
        expect(body(financed: financed)).to eq(baseline)
      end
    end

    it "files no lien when financed is omitted" do
      expect(described_class.call(payload.except(:financed)).body).to eq(baseline)
    end

    it "never returns a paper filing method" do
      expect(body(financed: true, lienholder_elt: false)[:lien_filing_method]).to eq("electronic")
    end
  end

  describe "buyer state" do
    [nil, "", " ", "NY", "ny"].each do |buyer|
      it "returns 30-day tags for #{buyer.inspect}" do
        expect(body(buyer_state: buyer)).to eq(baseline)
      end
    end

    it "returns 30-day tags when buyer state is omitted" do
      expect(described_class.call(payload.except(:buyer_state)).body).to eq(baseline)
    end

    %w[NJ nj ZZ].each do |buyer|
      it "returns 10-day tags for #{buyer.inspect}" do
        expect(body(buyer_state: buyer)).to eq(baseline.merge(temp_tag_valid_days: 10, temp_tag_expires_on: "2025-06-20"))
      end
    end
  end

  describe "delivery date" do
    {
      "2025-06-10" => "2025-07-10",
      "20250610" => "2025-07-10",
      "2025-6-1" => "2025-07-01",
      "06/10/2025" => "2025-11-05",
      "2025-12-02" => "2026-01-01",
      "2025-12-01" => "2025-12-31",
      "2024-01-30" => "2024-02-29"
    }.each do |delivery, expiry|
      it "expires in-state tags delivered #{delivery.inspect} on #{expiry}" do
        expect(body(delivery_date: delivery)).to include(temp_tag_valid_days: 30, temp_tag_expires_on: expiry)
      end
    end

    {
      "2025-12-21" => "2025-12-31",
      "2025-12-22" => "2026-01-01",
      "2024-02-19" => "2024-02-29",
      "2024-02-20" => "2024-03-01"
    }.each do |delivery, expiry|
      it "expires out-of-state tags delivered #{delivery.inspect} on #{expiry}" do
        expect(body(delivery_date: delivery, buyer_state: "NJ")).to include(temp_tag_valid_days: 10, temp_tag_expires_on: expiry)
      end
    end

    ["2025-02-30", "not a date", "", nil].each do |delivery|
      it "rejects #{delivery.inspect}" do
        expect(quote(delivery_date: delivery).to_h).to eq(
          status: :unprocessable_entity,
          body: { error: "Invalid request", details: ["Delivery date must be a valid YYYY-MM-DD date"] }
        )
      end
    end
  end

  it "matches the rule outputs for the same normalized input" do
    response = body(vehicle_weight_lbs: 5_500, vehicle_price_usd: 1_234.56, financed: true, buyer_state: "PA", delivery_date: "2025-12-22")
    input = Jurisdictions::QuoteInput.new(
      jurisdiction: "NY", weight_lbs: 5_500, purchase_price_cents: 123_456, financing: "loan",
      buyer_jurisdiction: "PA", delivery_date: Date.new(2025, 12, 22)
    )
    rule = Jurisdictions::NewYork

    expect(response).to eq(
      registration_fee_cents: rule.registration_fee_cents(input),
      ev_surcharge_cents: rule.ev_surcharge_cents(input),
      temp_tag_valid_days: rule.temp_tag_valid_days(input),
      temp_tag_expires_on: rule.temp_tag_expires_on(input).iso8601,
      lien_filing_required: rule.lien_filing_required?(input),
      lien_filing_method: rule.lien_filing_method(input),
      total_cents: rule.total_cents(input)
    )
    expect(response).to eq(
      registration_fee_cents: 8_281,
      ev_surcharge_cents: 7_500,
      temp_tag_valid_days: 10,
      temp_tag_expires_on: "2026-01-01",
      lien_filing_required: true,
      lien_filing_method: "electronic",
      total_cents: 15_781
    )
  end
end

RSpec.describe "POST /registration_quotes for NY in legacy mode (characterization)", type: :request do
  it "returns the RegistrationQuoteService body" do
    GoRouting::Route.find_or_initialize_by(jurisdiction_code: "NY").update!(mode: "legacy")
    params = { state: "ny", vehicle_weight_lbs: 3_500, vehicle_price_usd: 48_990, financed: true, buyer_state: "NJ", delivery_date: "2025-06-10" }

    post "/registration_quotes", params: params.to_json, headers: { "CONTENT_TYPE" => "application/json" }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(
      "registration_fee_cents" => 27_226,
      "ev_surcharge_cents" => 7_500,
      "temp_tag_valid_days" => 10,
      "temp_tag_expires_on" => "2025-06-20",
      "lien_filing_required" => true,
      "lien_filing_method" => "electronic",
      "total_cents" => 34_726
    )
  end
end
