require "rails_helper"

RSpec.describe Jurisdictions::Texas do
  let(:delivery_date) { Date.new(2025, 6, 10) }

  def input(**attributes)
    Jurisdictions::QuoteInput.new({
      jurisdiction: "TX",
      weight_lbs: 4_200,
      purchase_price_cents: 4_899_000,
      delivery_date: delivery_date
    }.merge(attributes))
  end

  def line_items(**attributes)
    described_class.fee_line_items(input(**attributes)).map(&:to_h)
  end

  describe "identity and constants" do
    it "is registered as TX with fixed metadata" do
      expect(described_class.code).to eq("TX")
      expect(Jurisdictions.for("tx")).to eq(described_class)
      expect(described_class.display_name).to eq("Texas")
      expect(described_class.country).to eq("US")
      expect(described_class.currency).to eq("USD")
      expect(described_class.tier).to eq(1)
      expect(described_class.weight_tiers).to eq([[4_000, 5_075], [6_000, 6_250], [nil, 7_825]])
      expect(described_class.metadata).to eq(
        code: "TX",
        name: "Texas",
        country: "US",
        currency: "USD",
        tier: 1,
        weight_tiers: [[4_000, 5_075], [6_000, 6_250], [nil, 7_825]],
        ev_surcharge_cents: 20_000,
        temp_tag_days: 60,
        elt: true
      )
    end

    it "returns a fixed title fee, ELT availability, and lease lien requirement" do
      expect(described_class.title_fee_cents).to eq(3_300)
      expect(described_class.elt_available?).to be(true)
      expect(described_class.lease_lien_required?).to be(true)
    end
  end

  describe "QuoteInput defaults and normalization as seen by Texas" do
    it "defaults powertrain to bev, financing to cash, lienholder_elt to true, usage to personal" do
      quote = Jurisdictions::QuoteInput.new(jurisdiction: "TX", weight_lbs: 4_200, delivery_date: delivery_date)

      expect(quote.powertrain).to eq("bev")
      expect(quote.financing).to eq("cash")
      expect(quote.lienholder_elt).to be(true)
      expect(quote.usage).to eq("personal")
      expect(quote.county).to be_nil
      expect(quote.buyer_jurisdiction).to eq("TX")
      expect(quote.purchase_price_cents).to be_nil
      expect(quote.price_cents).to eq(0)
    end

    it "strips and upcases jurisdiction, buyer_jurisdiction, and county; blank becomes nil" do
      quote = input(jurisdiction: " tx ", buyer_jurisdiction: " ca ", county: " travis ")
      expect(quote.jurisdiction).to eq("TX")
      expect(quote.buyer_jurisdiction).to eq("CA")
      expect(quote.county).to eq("TRAVIS")

      blank = input(buyer_jurisdiction: "  ", county: "")
      expect(blank.buyer_jurisdiction).to eq("TX")
      expect(blank.county).to be_nil
    end

    it "does not normalize powertrain, financing, or usage" do
      quote = input(powertrain: " BEV ", financing: "LOAN", usage: "Commercial")
      expect(quote.powertrain).to eq(" BEV ")
      expect(quote.financing).to eq("LOAN")
      expect(quote.usage).to eq("Commercial")
    end

    it "casts weight_lbs to an integer by truncation, and non-numeric strings to 0" do
      expect(input(weight_lbs: "4000").weight_lbs).to eq(4_000)
      expect(input(weight_lbs: "4000.9").weight_lbs).to eq(4_000)
      expect(input(weight_lbs: 4_000.9).weight_lbs).to eq(4_000)
      expect(input(weight_lbs: "abc").weight_lbs).to eq(0)
    end

    it "casts delivery_date strings, and invalid dates become nil" do
      expect(input(delivery_date: "2025-06-10").delivery_date).to eq(Date.new(2025, 6, 10))
      expect(input(delivery_date: "2025-02-30").delivery_date).to be_nil
    end

    it "casts lienholder_elt with ActiveModel boolean rules" do
      expect(input(lienholder_elt: "true").lienholder_elt).to be(true)
      expect(input(lienholder_elt: "no").lienholder_elt).to be(true)
      expect(input(lienholder_elt: "false").lienholder_elt).to be(false)
      expect(input(lienholder_elt: "0").lienholder_elt).to be(false)
      expect(input(lienholder_elt: "").lienholder_elt).to be_nil
      expect(input(lienholder_elt: nil).lienholder_elt).to be_nil
    end
  end

  describe ".fee_line_items" do
    it "returns registration, county fee, and EV surcharge line items in that order" do
      expect(line_items(weight_lbs: 4_200, county: "travis", powertrain: "bev")).to eq([
        { code: "registration", label: "4,001–6,000 lbs", amount_cents: 6_250 },
        { code: "county_fee", label: "County fee", amount_cents: 1_000 },
        { code: "ev_surcharge", label: "EV surcharge", amount_cents: 20_000 }
      ])
    end

    it "returns Jurisdictions::LineItem structs" do
      expect(described_class.fee_line_items(input)).to all(be_a(Jurisdictions::LineItem))
    end

    describe "weight tier edges" do
      {
        -1 => [5_075, "Up to 4,000 lbs"],
        0 => [5_075, "Up to 4,000 lbs"],
        1 => [5_075, "Up to 4,000 lbs"],
        3_999 => [5_075, "Up to 4,000 lbs"],
        4_000 => [5_075, "Up to 4,000 lbs"],
        4_001 => [6_250, "4,001–6,000 lbs"],
        5_999 => [6_250, "4,001–6,000 lbs"],
        6_000 => [7_825, "Over 6,000 lbs"],
        6_001 => [7_825, "Over 6,000 lbs"],
        20_000 => [7_825, "Over 6,000 lbs"]
      }.each do |weight, (amount, label)|
        it "charges #{amount} labelled #{label.inspect} at #{weight} lbs" do
          expect(line_items(weight_lbs: weight, powertrain: "ice")).to eq([
            { code: "registration", label: label, amount_cents: amount }
          ])
        end
      end

      it "uses truncated integer weights from string and float input" do
        expect(described_class.registration_fee_cents(input(weight_lbs: "4000.9"))).to eq(5_075)
        expect(described_class.registration_fee_cents(input(weight_lbs: 5_999.99))).to eq(6_250)
      end

      it "raises NoMethodError when weight_lbs is nil" do
        expect { described_class.fee_line_items(input(weight_lbs: nil)) }
          .to raise_error(NoMethodError, /undefined method `<=' for nil/)
      end

      it "charges the lowest tier for non-numeric weight strings, which cast to 0" do
        expect(described_class.registration_fee_cents(input(weight_lbs: "abc"))).to eq(5_075)
      end

      it "labels 6,000 lbs differently in fee_line_items than in the shared weight_tier_label helper" do
        expect(line_items(weight_lbs: 6_000).first[:label]).to eq("Over 6,000 lbs")
        expect(described_class.weight_tier_label(6_000)).to eq("4001–6000 lbs")
        expect(described_class.weight_tier_label(4_000)).to eq("1–4000 lbs")
        expect(described_class.weight_tier_label(4_001)).to eq("4001–6000 lbs")
        expect(described_class.weight_tier_label(6_001)).to eq("Over 6000 lbs")
      end
    end

    describe "county fees" do
      {
        "TRAVIS" => 1_000,
        "HARRIS" => 1_100,
        "DALLAS" => 1_150,
        "BEXAR" => 950
      }.each do |county, amount|
        it "adds #{amount} for #{county}" do
          expect(line_items(county: county, powertrain: "ice")).to eq([
            { code: "registration", label: "4,001–6,000 lbs", amount_cents: 6_250 },
            { code: "county_fee", label: "County fee", amount_cents: amount }
          ])
        end
      end

      it "normalizes county case and whitespace before lookup" do
        expect(described_class.registration_fee_cents(input(county: "  harris "))).to eq(7_350)
        expect(described_class.registration_fee_cents(input(county: "Bexar"))).to eq(7_200)
      end

      it "omits the county line item for unlisted, blank, or nil counties" do
        [nil, "", "   ", "TARRANT", "EL PASO", "TRAVIS COUNTY", "LOS ANGELES"].each do |county|
          expect(line_items(county: county, powertrain: "ice").map { |item| item[:code] }).to eq(["registration"])
        end
      end
    end

    describe "EV surcharge" do
      it "adds 20,000 for bev, 7,500 for phev, and nothing for ice" do
        expect(line_items(powertrain: "bev").last).to eq(code: "ev_surcharge", label: "EV surcharge", amount_cents: 20_000)
        expect(line_items(powertrain: "phev").last).to eq(code: "ev_surcharge", label: "EV surcharge", amount_cents: 7_500)
        expect(line_items(powertrain: "ice").map { |item| item[:code] }).to eq(["registration"])
      end

      it "applies the bev surcharge when powertrain is omitted" do
        quote = Jurisdictions::QuoteInput.new(jurisdiction: "TX", weight_lbs: 4_200, delivery_date: delivery_date)
        expect(described_class.ev_surcharge_cents(quote)).to eq(20_000)
      end

      it "adds no surcharge for nil or non-exact powertrain values" do
        [nil, "", "BEV", "Phev", " bev", "hybrid", "ev"].each do |powertrain|
          expect(described_class.ev_surcharge_cents(input(powertrain: powertrain))).to eq(0)
        end
      end
    end

    describe "inputs that do not affect fees" do
      let(:baseline) { line_items }

      it "ignores purchase price at every threshold, including nil and negative" do
        [nil, -1, 0, 1, 99, 100, 2_500_000, 4_899_000, 10_000_000, 1_000_000_000].each do |price|
          expect(line_items(purchase_price_cents: price)).to eq(baseline)
        end
      end

      it "ignores financing type and lienholder ELT" do
        %w[cash loan lease refinance].each do |financing|
          [true, false].each do |elt|
            expect(line_items(financing: financing, lienholder_elt: elt)).to eq(baseline)
          end
        end
      end

      it "ignores usage, buyer jurisdiction, delivery date, and the input jurisdiction code" do
        expect(line_items(usage: "commercial")).to eq(baseline)
        expect(line_items(buyer_jurisdiction: "CA")).to eq(baseline)
        expect(line_items(delivery_date: nil)).to eq(baseline)
        expect(line_items(jurisdiction: "CA")).to eq(baseline)
      end
    end
  end

  describe "fee totals" do
    it "includes county fee but excludes EV surcharge from registration_fee_cents" do
      quote = input(weight_lbs: 6_000, county: "dallas", powertrain: "bev")
      expect(described_class.registration_fee_cents(quote)).to eq(8_975)
      expect(described_class.ev_surcharge_cents(quote)).to eq(20_000)
      expect(described_class.total_cents(quote)).to eq(28_975)
    end

    {
      [4_000, nil, "ice"] => [5_075, 0, 5_075],
      [4_000, nil, "bev"] => [5_075, 20_000, 25_075],
      [4_001, "BEXAR", "phev"] => [7_200, 7_500, 14_700],
      [5_999, "HARRIS", "ice"] => [7_350, 0, 7_350],
      [6_000, "TRAVIS", "phev"] => [8_825, 7_500, 16_325],
      [6_001, "DALLAS", "bev"] => [8_975, 20_000, 28_975]
    }.each do |(weight, county, powertrain), (registration, ev, total)|
      it "returns #{registration}/#{ev}/#{total} for #{weight} lbs, county #{county.inspect}, #{powertrain}" do
        quote = input(weight_lbs: weight, county: county, powertrain: powertrain)
        expect(described_class.registration_fee_cents(quote)).to eq(registration)
        expect(described_class.ev_surcharge_cents(quote)).to eq(ev)
        expect(described_class.total_cents(quote)).to eq(total)
      end
    end
  end

  describe "temporary tags" do
    it "is valid for 60 days for an in-state buyer" do
      expect(described_class.temp_tag_valid_days(input)).to eq(60)
      expect(described_class.temp_tag_valid_days(input(buyer_jurisdiction: "TX"))).to eq(60)
      expect(described_class.temp_tag_valid_days(input(buyer_jurisdiction: " tx "))).to eq(60)
      expect(described_class.temp_tag_valid_days(input(buyer_jurisdiction: nil))).to eq(60)
      expect(described_class.temp_tag_valid_days(input(buyer_jurisdiction: ""))).to eq(60)
    end

    it "is valid for 30 days for any buyer jurisdiction other than the input jurisdiction" do
      %w[CA OK NM ON ZZ].each do |buyer|
        expect(described_class.temp_tag_valid_days(input(buyer_jurisdiction: buyer))).to eq(30)
      end
    end

    it "compares buyer to the input jurisdiction, not to TX" do
      expect(described_class.temp_tag_valid_days(input(jurisdiction: "CA"))).to eq(60)
      expect(described_class.temp_tag_valid_days(input(jurisdiction: "CA", buyer_jurisdiction: "TX"))).to eq(30)
      expect(described_class.temp_tag_valid_days(input(jurisdiction: nil, buyer_jurisdiction: nil))).to eq(60)
    end

    it "ignores usage, financing, powertrain, weight, and price" do
      quote = input(usage: "commercial", financing: "lease", powertrain: "ice", weight_lbs: 9_000, purchase_price_cents: 0)
      expect(described_class.temp_tag_valid_days(quote)).to eq(60)
      expect(described_class.temp_tag_valid_days(input(usage: "commercial", buyer_jurisdiction: "CA"))).to eq(30)
    end

    it "does not use the TEMP_TAG_DAYS constant path from Base" do
      expect(described_class::TEMP_TAG_DAYS).to eq(60)
      expect(described_class.method(:temp_tag_valid_days).owner).to eq(described_class.singleton_class)
    end

    describe ".temp_tag_expires_on" do
      {
        [Date.new(2025, 6, 10), nil] => Date.new(2025, 8, 9),
        [Date.new(2025, 6, 10), "CA"] => Date.new(2025, 7, 10),
        [Date.new(2025, 1, 1), nil] => Date.new(2025, 3, 2),
        [Date.new(2025, 1, 1), "CA"] => Date.new(2025, 1, 31),
        [Date.new(2024, 1, 1), nil] => Date.new(2024, 3, 1),
        [Date.new(2024, 1, 31), "CA"] => Date.new(2024, 3, 1),
        [Date.new(2025, 1, 31), "CA"] => Date.new(2025, 3, 2),
        [Date.new(2025, 12, 31), nil] => Date.new(2026, 3, 1),
        [Date.new(2025, 12, 31), "CA"] => Date.new(2026, 1, 30),
        [Date.new(2025, 11, 2), nil] => Date.new(2026, 1, 1),
        [Date.new(2025, 12, 2), "CA"] => Date.new(2026, 1, 1)
      }.each do |(date, buyer), expected|
        it "expires on #{expected} for delivery #{date} and buyer #{buyer.inspect}" do
          quote = input(delivery_date: date, buyer_jurisdiction: buyer)
          expect(described_class.temp_tag_expires_on(quote)).to eq(expected)
          expect(described_class.temp_tag_expires_on(quote) - date).to eq(described_class.temp_tag_valid_days(quote))
        end
      end

      it "accepts an ISO date string through QuoteInput casting" do
        expect(described_class.temp_tag_expires_on(input(delivery_date: "2025-06-10"))).to eq(Date.new(2025, 8, 9))
      end

      it "raises NoMethodError when delivery_date is nil or an invalid date" do
        expect { described_class.temp_tag_expires_on(input(delivery_date: nil)) }
          .to raise_error(NoMethodError, /undefined method `\+' for nil/)
        expect { described_class.temp_tag_expires_on(input(delivery_date: "2025-02-30")) }.to raise_error(NoMethodError)
      end
    end
  end

  describe "lien filing" do
    def lien(financing:, lienholder_elt: true)
      quote = input(financing: financing, lienholder_elt: lienholder_elt)
      [
        described_class.lien_filing_required?(quote),
        described_class.lien_filing_method(quote),
        described_class.lien_reason(quote)
      ]
    end

    electronic = "Electronic filing via Texas ELT"
    paper = "Paper filing with Texas motor vehicle agency"
    none = "No lien to record"

    {
      ["cash", true] => [false, nil, none],
      ["cash", false] => [false, nil, none],
      ["loan", true] => [true, "electronic", electronic],
      ["loan", false] => [true, "paper", paper],
      ["loan", nil] => [true, "paper", paper],
      ["refinance", true] => [true, "electronic", electronic],
      ["refinance", false] => [true, "paper", paper],
      ["lease", true] => [true, "electronic", electronic],
      ["lease", false] => [true, "paper", paper],
      ["lease", nil] => [true, "paper", paper]
    }.each do |(financing, elt), expected|
      it "returns #{expected.inspect} for #{financing} with lienholder_elt #{elt.inspect}" do
        expect(lien(financing: financing, lienholder_elt: elt)).to eq(expected)
      end
    end

    it "treats omitted financing as cash and omitted lienholder_elt as true" do
      quote = Jurisdictions::QuoteInput.new(jurisdiction: "TX", financing: "loan")
      expect(described_class.lien_filing_method(quote)).to eq("electronic")

      cash = Jurisdictions::QuoteInput.new(jurisdiction: "TX")
      expect(described_class.lien_filing_required?(cash)).to be(false)
    end

    it "treats unsupported or differently cased financing values as no lien" do
      [nil, "", "LOAN", "Lease", " loan", "Refinance", "finance", "balloon"].each do |financing|
        expect(lien(financing: financing)).to eq([false, nil, none])
      end
    end

    it "uses ActiveModel boolean casting for lienholder_elt strings" do
      expect(lien(financing: "loan", lienholder_elt: "false")).to eq([true, "paper", paper])
      expect(lien(financing: "loan", lienholder_elt: "0")).to eq([true, "paper", paper])
      expect(lien(financing: "loan", lienholder_elt: "")).to eq([true, "paper", paper])
      expect(lien(financing: "loan", lienholder_elt: "no")).to eq([true, "electronic", electronic])
      expect(lien(financing: "loan", lienholder_elt: "1")).to eq([true, "electronic", electronic])
    end

    it "ignores buyer jurisdiction, weight, price, usage, and county" do
      quote = input(financing: "lease", lienholder_elt: true, buyer_jurisdiction: "CA", weight_lbs: 9_000,
                    purchase_price_cents: 0, usage: "commercial", county: "TRAVIS")
      expect(described_class.lien_filing_required?(quote)).to be(true)
      expect(described_class.lien_filing_method(quote)).to eq("electronic")
    end

    it "matches LienFilings::DeterminationService results" do
      %w[cash loan lease refinance].each do |financing|
        [true, false].each do |elt|
          quote = input(financing: financing, lienholder_elt: elt)
          result = LienFilings::DeterminationService.call(quote)
          expect(result.jurisdiction).to eq(described_class)
          expect([result.required, result.filing_method, result.reason]).to eq(lien(financing: financing, lienholder_elt: elt))
        end
      end
    end
  end
end
