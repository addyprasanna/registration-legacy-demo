require "rails_helper"

RSpec.describe Jurisdictions::Ontario, "characterization" do
  def input(**attributes)
    Jurisdictions::QuoteInput.new({
      jurisdiction: "ON",
      weight_lbs: 4_200,
      purchase_price_cents: 4_899_000,
      delivery_date: Date.new(2025, 6, 10)
    }.merge(attributes))
  end

  def line_items(quote)
    described_class.fee_line_items(quote).map { |item| [item.code, item.label, item.amount_cents] }
  end

  describe "identity and static rule values" do
    it "is registered under ON and resolved by the registry" do
      expect(described_class.code).to eq("ON")
      expect(Jurisdictions.for("ON")).to be(described_class)
      expect(Jurisdictions.for(" on ")).to be(described_class)
    end

    it "reports CAD currency with country CA" do
      expect(described_class.currency).to eq("CAD")
      expect(described_class.country).to eq("CA")
      expect(described_class.display_name).to eq("Ontario")
      expect(described_class.tier).to eq(1)
    end

    it "exposes ELT availability, lease lien requirement and title fee" do
      expect(described_class.elt_available?).to be(true)
      expect(described_class.lease_lien_required?).to be(true)
      expect(described_class.title_fee_cents).to eq(3_200)
    end

    it "exposes weight tiers and metadata" do
      expect(described_class.weight_tiers).to eq([[3_299, 5_900], [5_499, 9_000], [nil, 12_000]])
      expect(described_class.metadata).to eq(
        code: "ON",
        name: "Ontario",
        country: "CA",
        currency: "CAD",
        tier: 1,
        weight_tiers: [[3_299, 5_900], [5_499, 9_000], [nil, 12_000]],
        ev_surcharge_cents: 5_000,
        temp_tag_days: 40,
        elt: true
      )
    end

    it "includes OntarioRules as instance methods only" do
      expect(described_class.include?(OntarioRules)).to be(true)
      expect(described_class.respond_to?(:ontario_round)).to be(false)
      expect(described_class.new.respond_to?(:ontario_round)).to be(true)
    end
  end

  describe ".weight_tier_label" do
    {
      -1 => "1–3299 lbs",
      0 => "1–3299 lbs",
      1 => "1–3299 lbs",
      3_299 => "1–3299 lbs",
      3_300 => "3300–5499 lbs",
      5_499 => "3300–5499 lbs",
      5_500 => "Over 5499 lbs",
      20_000 => "Over 5499 lbs"
    }.each do |weight, label|
      it "labels #{weight} lbs as #{label.inspect}" do
        expect(described_class.weight_tier_label(weight)).to eq(label)
      end
    end

    it "raises NoMethodError for a nil weight" do
      expect { described_class.weight_tier_label(nil) }.to raise_error(NoMethodError)
    end
  end

  describe ".fee_line_items" do
    it "returns registration, retail sales tax and EV surcharge lines for the default input" do
      expect(line_items(input)).to eq([
        ["registration", "Registration", 9_000],
        ["rst", "Retail sales tax", 165_341],
        ["ev_surcharge", "EV surcharge", 5_000]
      ])
    end

    it "returns Jurisdictions::LineItem structs" do
      expect(described_class.fee_line_items(input)).to all(be_a(Jurisdictions::LineItem))
    end

    describe "registration base fee by weight" do
      {
        nil => 12_000,
        -1 => 12_000,
        0 => 5_900,
        1 => 5_900,
        3_299 => 5_900,
        3_300 => 9_000,
        5_499 => 9_000,
        5_500 => 12_000,
        20_000 => 12_000
      }.each do |weight, cents|
        it "charges #{cents} for weight #{weight.inspect}" do
          quote = input(weight_lbs: weight, purchase_price_cents: 0)
          expect(line_items(quote).first).to eq(["registration", "Registration", cents])
          expect(described_class.registration_fee_cents(quote)).to eq(cents)
        end
      end
    end

    describe "retail sales tax (price cents x 1.35 x 0.025, banker's rounding)" do
      {
        nil => nil,
        -1_000 => nil,
        0 => nil,
        14 => nil,
        15 => 1,
        400 => 14,
        1_200 => 40,
        2_000 => 68,
        4_899_000 => 165_341,
        1_000_000_000 => 33_750_000
      }.each do |price, rst|
        it "#{rst ? "adds an rst line of #{rst}" : 'omits the rst line'} for purchase_price_cents #{price.inspect}" do
          rst_line = described_class.fee_line_items(input(purchase_price_cents: price)).find { |item| item.code == "rst" }
          expect(rst_line&.amount_cents).to eq(rst)
        end
      end

      it "keeps the registration line at the weight base when the price is negative" do
        expect(line_items(input(purchase_price_cents: -1_000))).to eq([
          ["registration", "Registration", 9_000],
          ["ev_surcharge", "EV surcharge", 5_000]
        ])
      end
    end

    describe "EV surcharge by powertrain" do
      { "bev" => 5_000, "phev" => 2_500, "ice" => nil, nil => nil, "BEV" => nil, "hybrid" => nil }.each do |powertrain, cents|
        it "#{cents ? "adds #{cents}" : 'omits the line'} for powertrain #{powertrain.inspect}" do
          ev_line = described_class.fee_line_items(input(powertrain: powertrain)).find { |item| item.code == "ev_surcharge" }
          expect(ev_line&.amount_cents).to eq(cents)
        end
      end
    end

    it "uses the default QuoteInput attributes when nothing is supplied" do
      expect(line_items(Jurisdictions::QuoteInput.new)).to eq([
        ["registration", "Registration", 12_000],
        ["ev_surcharge", "EV surcharge", 5_000]
      ])
    end

    it "does not depend on delivery date, usage, financing, lienholder ELT, buyer jurisdiction or county" do
      baseline = line_items(input)
      variations = [
        { delivery_date: nil },
        { usage: "commercial" },
        { financing: "loan" },
        { financing: "lease" },
        { financing: "refinance" },
        { lienholder_elt: false },
        { buyer_jurisdiction: "CA" },
        { buyer_jurisdiction: "QC" },
        { county: "TORONTO" }
      ]
      variations.each do |variation|
        expect(line_items(input(**variation))).to eq(baseline), "expected no change for #{variation.inspect}"
      end
    end
  end

  describe "fee totals" do
    {
      "bev" => [174_341, 5_000, 179_341],
      "phev" => [174_341, 2_500, 176_841],
      "ice" => [174_341, 0, 174_341],
      nil => [174_341, 0, 174_341]
    }.each do |powertrain, (registration, ev, total)|
      it "returns registration #{registration}, EV #{ev}, total #{total} for powertrain #{powertrain.inspect}" do
        quote = input(powertrain: powertrain)
        expect(described_class.registration_fee_cents(quote)).to eq(registration)
        expect(described_class.ev_surcharge_cents(quote)).to eq(ev)
        expect(described_class.total_cents(quote)).to eq(total)
      end
    end

    it "includes retail sales tax in registration_fee_cents" do
      quote = input(weight_lbs: 3_299, purchase_price_cents: 1_200, powertrain: "ice")
      expect(described_class.registration_fee_cents(quote)).to eq(5_940)
      expect(described_class.total_cents(quote)).to eq(5_940)
    end

    it "returns the weight base plus EV surcharge when the price is zero" do
      quote = input(weight_lbs: 5_500, purchase_price_cents: 0)
      expect(described_class.registration_fee_cents(quote)).to eq(12_000)
      expect(described_class.total_cents(quote)).to eq(17_000)
    end
  end

  describe ".temp_tag_valid_days and .temp_tag_expires_on" do
    { "personal" => 40, "commercial" => 10, nil => 40, "Commercial" => 40, "fleet" => 40 }.each do |usage, days|
      it "grants #{days} days for usage #{usage.inspect}" do
        expect(described_class.temp_tag_valid_days(input(usage: usage))).to eq(days)
      end
    end

    {
      [Date.new(2025, 6, 10), "personal"] => Date.new(2025, 7, 20),
      [Date.new(2025, 6, 10), "commercial"] => Date.new(2025, 6, 20),
      [Date.new(2024, 2, 20), "personal"] => Date.new(2024, 3, 31),
      [Date.new(2024, 2, 20), "commercial"] => Date.new(2024, 3, 1),
      [Date.new(2023, 2, 20), "commercial"] => Date.new(2023, 3, 2),
      [Date.new(2024, 12, 25), "personal"] => Date.new(2025, 2, 3),
      [Date.new(2024, 12, 22), "commercial"] => Date.new(2025, 1, 1),
      [Date.new(2025, 1, 31), "personal"] => Date.new(2025, 3, 12),
      [Date.new(2025, 1, 31), "commercial"] => Date.new(2025, 2, 10)
    }.each do |(delivery_date, usage), expires_on|
      it "expires a #{usage} tag delivered #{delivery_date} on #{expires_on}" do
        expect(described_class.temp_tag_expires_on(input(delivery_date: delivery_date, usage: usage))).to eq(expires_on)
      end
    end

    it "casts an ISO date string delivery_date before adding days" do
      expect(described_class.temp_tag_expires_on(input(delivery_date: "2025-06-10"))).to eq(Date.new(2025, 7, 20))
    end

    it "raises NoMethodError when delivery_date is nil" do
      expect { described_class.temp_tag_expires_on(input(delivery_date: nil)) }.to raise_error(NoMethodError)
    end

    it "ignores buyer jurisdiction" do
      expect(described_class.temp_tag_valid_days(input(buyer_jurisdiction: "TX"))).to eq(40)
    end
  end

  describe "lien filing determination" do
    {
      "cash" => [false, nil, "No lien to record"],
      "loan" => [true, "electronic", "Electronic filing via Ontario ELT"],
      "lease" => [true, "electronic", "Electronic filing via Ontario ELT"],
      "refinance" => [true, "electronic", "Electronic filing via Ontario ELT"],
      nil => [false, nil, "No lien to record"],
      "LOAN" => [false, nil, "No lien to record"],
      "other" => [false, nil, "No lien to record"]
    }.each do |financing, (required, method, reason)|
      [true, false].each do |elt|
        it "returns required=#{required}, method=#{method.inspect} for financing #{financing.inspect} with lienholder_elt=#{elt}" do
          quote = input(financing: financing, lienholder_elt: elt)
          expect(described_class.lien_filing_required?(quote)).to be(required)
          expect(described_class.lien_filing_method(quote)).to eq(method)
          expect(described_class.lien_reason(quote)).to eq(reason)
        end
      end
    end

    it "never returns a paper filing method" do
      %w[cash loan lease refinance].product([true, false, nil]).each do |financing, elt|
        expect(described_class.lien_filing_method(input(financing: financing, lienholder_elt: elt))).not_to eq("paper")
      end
    end
  end

  describe "QuoteInput normalization as seen by Ontario" do
    it "strips and upcases codes and casts string attributes" do
      quote = input(
        jurisdiction: " on ",
        weight_lbs: "3300",
        purchase_price_cents: "1200",
        delivery_date: "2024-02-20",
        lienholder_elt: "false",
        buyer_jurisdiction: "",
        county: " york "
      )

      expect(quote).to have_attributes(jurisdiction: "ON", weight_lbs: 3_300, price_cents: 1_200,
                                       delivery_date: Date.new(2024, 2, 20), lienholder_elt: false,
                                       buyer_jurisdiction: "ON", county: "YORK", out_of_state_buyer?: false)
      expect(line_items(quote)).to eq([
        ["registration", "Registration", 9_000],
        ["rst", "Retail sales tax", 40],
        ["ev_surcharge", "EV surcharge", 5_000]
      ])
      expect(described_class.temp_tag_expires_on(quote)).to eq(Date.new(2024, 3, 31))
    end

    it "truncates fractional weight and price inputs" do
      quote = input(weight_lbs: "3299.9", purchase_price_cents: 1_200.9)
      expect(quote.weight_lbs).to eq(3_299)
      expect(quote.price_cents).to eq(1_200)
      expect(described_class.registration_fee_cents(quote)).to eq(5_940)
    end

    it "uses QuoteInput defaults" do
      expect(Jurisdictions::QuoteInput.new.attributes).to include(
        "powertrain" => "bev", "financing" => "cash", "lienholder_elt" => true, "usage" => "personal"
      )
    end
  end
end
