require "rails_helper"

RSpec.describe Jurisdictions::Washington, "characterization" do
  let(:delivery_date) { Date.new(2025, 6, 10) }

  def input(**attributes)
    Jurisdictions::QuoteInput.new({
      jurisdiction: "WA",
      weight_lbs: 4_200,
      purchase_price_cents: 4_899_000,
      delivery_date: delivery_date
    }.merge(attributes))
  end

  def item_pairs(quote)
    described_class.fee_line_items(quote).map { |item| [item.code, item.amount_cents] }
  end

  describe "class-level attributes" do
    it "is registered under WA and exposes its static values" do
      expect(Jurisdictions.for("WA")).to eq(described_class)
      expect(Jurisdictions.for(" wa ")).to eq(described_class)
      expect(described_class.code).to eq("WA")
      expect(described_class.display_name).to eq("Washington")
      expect(described_class.country).to eq("US")
      expect(described_class.currency).to eq("USD")
      expect(described_class.tier).to eq(1)
    end

    it "returns the title fee" do
      expect(described_class.title_fee_cents).to eq(3_500)
    end

    it "reports ELT availability and lease lien requirement" do
      expect(described_class.elt_available?).to be(true)
      expect(described_class.lease_lien_required?).to be(true)
    end

    it "exposes weight tiers and metadata" do
      expect(described_class.weight_tiers).to eq([[3_999, 4_500], [4_999, 5_850], [6_499, 7_300], [nil, 9_600]])
      expect(described_class.metadata).to eq(
        code: "WA",
        name: "Washington",
        country: "US",
        currency: "USD",
        tier: 1,
        weight_tiers: [[3_999, 4_500], [4_999, 5_850], [6_499, 7_300], [nil, 9_600]],
        ev_surcharge_cents: 15_000,
        temp_tag_days: 45,
        elt: true
      )
    end
  end

  describe "QuoteInput defaults used by the rules" do
    it "defaults powertrain, financing, lienholder_elt, usage and buyer jurisdiction" do
      quote = input
      expect(quote.powertrain).to eq("bev")
      expect(quote.financing).to eq("cash")
      expect(quote.lienholder_elt).to be(true)
      expect(quote.usage).to eq("personal")
      expect(quote.county).to be_nil
      expect(quote.buyer_jurisdiction).to eq("WA")
    end

    it "returns the default fee breakdown" do
      expect(described_class.fee_line_items(input).map(&:to_h)).to eq([
        { code: "registration", label: "Registration", amount_cents: 5_850 },
        { code: "ev_surcharge", label: "EV surcharge", amount_cents: 15_000 }
      ])
      expect(described_class.registration_fee_cents(input)).to eq(5_850)
      expect(described_class.ev_surcharge_cents(input)).to eq(15_000)
      expect(described_class.total_cents(input)).to eq(20_850)
    end
  end

  describe "registration fee weight tiers" do
    {
      0 => [4_500, "1–3999 lbs"],
      1 => [4_500, "1–3999 lbs"],
      3_999 => [4_500, "1–3999 lbs"],
      4_000 => [5_850, "4000–4999 lbs"],
      4_999 => [5_850, "4000–4999 lbs"],
      5_000 => [7_300, "5000–6499 lbs"],
      6_499 => [7_300, "5000–6499 lbs"],
      6_500 => [9_600, "Over 6499 lbs"],
      20_000 => [9_600, "Over 6499 lbs"]
    }.each do |weight, (fee, label)|
      it "charges #{fee} cents with tier label #{label.inspect} at #{weight} lbs" do
        quote = input(weight_lbs: weight, powertrain: "ice")
        expect(item_pairs(quote)).to eq([["registration", fee]])
        expect(described_class.registration_fee_cents(quote)).to eq(fee)
        expect(described_class.total_cents(quote)).to eq(fee)
        expect(described_class.weight_tier_label(weight)).to eq(label)
      end
    end

    it "places negative weights in the lowest tier" do
      expect(described_class.registration_fee_cents(input(weight_lbs: -5))).to eq(4_500)
      expect(described_class.weight_tier_label(-5)).to eq("1–3999 lbs")
    end

    it "casts string and fractional weights to integers before tier lookup" do
      expect(input(weight_lbs: "4000.9").weight_lbs).to eq(4_000)
      expect(described_class.registration_fee_cents(input(weight_lbs: "4000.9"))).to eq(5_850)
      expect(described_class.registration_fee_cents(input(weight_lbs: "3999"))).to eq(4_500)
    end

    it "raises NoMethodError when weight is nil" do
      expect { described_class.fee_line_items(input(weight_lbs: nil)) }.to raise_error(NoMethodError, /undefined method `<='/)
      expect { described_class.registration_fee_cents(input(weight_lbs: nil)) }.to raise_error(NoMethodError)
      expect { described_class.total_cents(input(weight_lbs: nil)) }.to raise_error(NoMethodError)
    end
  end

  describe "EV surcharge by powertrain" do
    {
      "bev" => [15_000, 20_850, %w[registration ev_surcharge]],
      "phev" => [7_500, 13_350, %w[registration ev_surcharge]],
      "ice" => [0, 5_850, %w[registration]],
      "BEV" => [0, 5_850, %w[registration]],
      "PHEV" => [0, 5_850, %w[registration]],
      "hybrid" => [0, 5_850, %w[registration]],
      "" => [0, 5_850, %w[registration]],
      nil => [0, 5_850, %w[registration]]
    }.each do |powertrain, (surcharge, total, codes)|
      it "returns #{surcharge} cents for powertrain #{powertrain.inspect}" do
        quote = input(powertrain: powertrain)
        expect(described_class.ev_surcharge_cents(quote)).to eq(surcharge)
        expect(described_class.registration_fee_cents(quote)).to eq(5_850)
        expect(described_class.total_cents(quote)).to eq(total)
        expect(described_class.fee_line_items(quote).map(&:code)).to eq(codes)
      end
    end

    it "labels the surcharge line item" do
      item = described_class.fee_line_items(input(powertrain: "phev")).last
      expect(item.to_h).to eq(code: "ev_surcharge", label: "EV surcharge", amount_cents: 7_500)
    end
  end

  describe "regional transit (RTA) tax by county" do
    it "uses the counties declared on CustomerAccounts::Vehicle" do
      expect(CustomerAccounts::Vehicle::WA_RTA_COUNTIES).to eq(%w[KING PIERCE SNOHOMISH])
    end

    CustomerAccounts::Vehicle::WA_RTA_COUNTIES.each do |county|
      it "adds 1.1% of the purchase price for #{county}" do
        quote = input(county: county)
        expect(described_class.fee_line_items(quote).map(&:to_h)).to eq([
          { code: "registration", label: "Registration", amount_cents: 5_850 },
          { code: "rta_tax", label: "Regional transit tax", amount_cents: 53_889 },
          { code: "ev_surcharge", label: "EV surcharge", amount_cents: 15_000 }
        ])
        expect(described_class.registration_fee_cents(quote)).to eq(59_739)
        expect(described_class.ev_surcharge_cents(quote)).to eq(15_000)
        expect(described_class.total_cents(quote)).to eq(74_739)
      end
    end

    it "matches RTA counties after strip and upcase normalization" do
      ["king", " Pierce ", "snohomish ", :king].each do |county|
        expect(described_class.registration_fee_cents(input(county: county))).to eq(59_739)
      end
      expect(input(county: " snohomish ").county).to eq("SNOHOMISH")
    end

    {
      "SPOKANE" => "SPOKANE",
      "clark" => "CLARK",
      "King County" => "KING COUNTY",
      "king  pierce" => "KING  PIERCE",
      "" => nil,
      "   " => nil,
      nil => nil
    }.each do |county, normalized|
      it "adds no RTA tax for non-RTA county #{county.inspect}" do
        quote = input(county: county)
        expect(quote.county).to eq(normalized)
        expect(item_pairs(quote)).to eq([["registration", 5_850], ["ev_surcharge", 15_000]])
        expect(described_class.registration_fee_cents(quote)).to eq(5_850)
        expect(described_class.total_cents(quote)).to eq(20_850)
      end
    end

    {
      0 => nil,
      1 => nil,
      45 => nil,
      46 => 1,
      90 => 1,
      91 => 1,
      499 => 5,
      500 => 6,
      1_500 => 17,
      4_545_454 => 50_000,
      4_545_455 => 50_000,
      4_899_000 => 53_889,
      100_000_000 => 1_100_000
    }.each do |price, tax|
      it "computes RTA tax #{tax.inspect} for a #{price} cent purchase price (half-up rounding)" do
        quote = input(county: "KING", purchase_price_cents: price, powertrain: "ice")
        expected = [["registration", 5_850]]
        expected << ["rta_tax", tax] if tax
        expect(item_pairs(quote)).to eq(expected)
        expect(described_class.registration_fee_cents(quote)).to eq(5_850 + tax.to_i)
      end
    end

    it "treats a nil purchase price as zero" do
      quote = input(county: "KING", purchase_price_cents: nil)
      expect(quote.price_cents).to eq(0)
      expect(item_pairs(quote)).to eq([["registration", 5_850], ["ev_surcharge", 15_000]])
    end

    it "casts a decimal string purchase price to whole cents before taxing" do
      quote = input(county: "KING", purchase_price_cents: "48990.50")
      expect(quote.purchase_price_cents).to eq(48_990)
      expect(item_pairs(quote)).to eq([["registration", 5_850], ["rta_tax", 539], ["ev_surcharge", 15_000]])
    end

    it "combines RTA tax with weight tier and powertrain" do
      quote = input(county: "PIERCE", weight_lbs: 6_500, powertrain: "phev", purchase_price_cents: 10_000_000)
      expect(item_pairs(quote)).to eq([["registration", 9_600], ["rta_tax", 110_000], ["ev_surcharge", 7_500]])
      expect(described_class.registration_fee_cents(quote)).to eq(119_600)
      expect(described_class.ev_surcharge_cents(quote)).to eq(7_500)
      expect(described_class.total_cents(quote)).to eq(127_100)
    end
  end

  describe "temporary tag validity" do
    {
      "personal" => [45, Date.new(2025, 7, 25)],
      "commercial" => [20, Date.new(2025, 6, 30)],
      "Commercial" => [45, Date.new(2025, 7, 25)],
      "COMMERCIAL" => [45, Date.new(2025, 7, 25)],
      "fleet" => [45, Date.new(2025, 7, 25)],
      "" => [45, Date.new(2025, 7, 25)],
      nil => [45, Date.new(2025, 7, 25)]
    }.each do |usage, (days, expires_on)|
      it "is #{days} days for usage #{usage.inspect}" do
        quote = input(usage: usage)
        expect(described_class.temp_tag_valid_days(quote)).to eq(days)
        expect(described_class.temp_tag_expires_on(quote)).to eq(expires_on)
      end
    end

    it "does not add fee line items for commercial usage" do
      expect(item_pairs(input(usage: "commercial"))).to eq([["registration", 5_850], ["ev_surcharge", 15_000]])
    end

    {
      Date.new(2024, 1, 15) => [Date.new(2024, 2, 29), Date.new(2024, 2, 4)],
      Date.new(2024, 2, 10) => [Date.new(2024, 3, 26), Date.new(2024, 3, 1)],
      Date.new(2025, 2, 10) => [Date.new(2025, 3, 27), Date.new(2025, 3, 2)],
      Date.new(2025, 12, 20) => [Date.new(2026, 2, 3), Date.new(2026, 1, 9)],
      Date.new(2025, 12, 31) => [Date.new(2026, 2, 14), Date.new(2026, 1, 20)]
    }.each do |delivered_on, (personal_expiry, commercial_expiry)|
      it "expires #{personal_expiry} (personal) and #{commercial_expiry} (commercial) for delivery on #{delivered_on}" do
        expect(described_class.temp_tag_expires_on(input(delivery_date: delivered_on))).to eq(personal_expiry)
        expect(described_class.temp_tag_expires_on(input(delivery_date: delivered_on, usage: "commercial"))).to eq(commercial_expiry)
        expect(personal_expiry - delivered_on).to eq(45)
        expect(commercial_expiry - delivered_on).to eq(20)
      end
    end

    it "ignores weight, price, powertrain, financing, county and buyer jurisdiction" do
      quote = input(weight_lbs: 9_000, purchase_price_cents: 0, powertrain: "ice", financing: "lease",
                    county: "KING", buyer_jurisdiction: "OR")
      expect(described_class.temp_tag_valid_days(quote)).to eq(45)
      expect(described_class.temp_tag_expires_on(quote)).to eq(Date.new(2025, 7, 25))
    end

    it "casts an ISO date string delivery date" do
      expect(described_class.temp_tag_expires_on(input(delivery_date: "2025-06-10"))).to eq(Date.new(2025, 7, 25))
    end

    it "raises NoMethodError when the delivery date is nil or uncastable" do
      expect(input(delivery_date: "2025-02-30").delivery_date).to be_nil
      expect { described_class.temp_tag_expires_on(input(delivery_date: nil)) }.to raise_error(NoMethodError, /undefined method `\+' for nil/)
      expect { described_class.temp_tag_expires_on(input(delivery_date: "2025-02-30")) }.to raise_error(NoMethodError)
    end

    it "still returns valid days when the delivery date is nil" do
      expect(described_class.temp_tag_valid_days(input(delivery_date: nil))).to eq(45)
    end
  end

  describe "lien filing determination" do
    electronic = [true, "electronic", "Electronic filing via Washington ELT"]
    paper = [true, "paper", "Paper filing with Washington motor vehicle agency"]
    none = [false, nil, "No lien to record"]

    {
      ["cash", true] => none,
      ["cash", false] => none,
      ["cash", nil] => none,
      ["loan", true] => electronic,
      ["loan", false] => paper,
      ["loan", nil] => paper,
      ["refinance", true] => electronic,
      ["refinance", false] => paper,
      ["refinance", nil] => paper,
      ["lease", true] => electronic,
      ["lease", false] => paper,
      ["lease", nil] => paper,
      ["LOAN", true] => none,
      ["Lease", true] => none,
      ["balloon", true] => none,
      ["", true] => none,
      [nil, true] => none
    }.each do |(financing, elt), (required, method, reason)|
      it "for financing #{financing.inspect} with lienholder_elt #{elt.inspect}: required=#{required}, method=#{method.inspect}" do
        quote = input(financing: financing, lienholder_elt: elt)
        expect(described_class.lien_filing_required?(quote)).to be(required)
        expect(described_class.lien_filing_method(quote)).to eq(method)
        expect(described_class.lien_reason(quote)).to eq(reason)
      end
    end

    {
      "true" => [true, "electronic"],
      "1" => [true, "electronic"],
      "yes" => [true, "electronic"],
      "no" => [true, "electronic"],
      "false" => [false, "paper"],
      "0" => [false, "paper"],
      "f" => [false, "paper"],
      "off" => [false, "paper"],
      "" => [nil, "paper"]
    }.each do |raw, (cast, method)|
      it "casts lienholder_elt #{raw.inspect} to #{cast.inspect} and files #{method} for a loan" do
        quote = input(financing: "loan", lienholder_elt: raw)
        expect(quote.lienholder_elt).to eq(cast)
        expect(described_class.lien_filing_method(quote)).to eq(method)
      end
    end

    it "uses the QuoteInput default financing (cash) and lienholder_elt (true)" do
      expect(described_class.lien_filing_required?(input)).to be(false)
      expect(described_class.lien_filing_method(input)).to be_nil
      expect(described_class.lien_filing_method(input(financing: "loan"))).to eq("electronic")
    end

    it "is unaffected by fee inputs and buyer jurisdiction" do
      quote = input(financing: "loan", lienholder_elt: false, county: "KING", weight_lbs: 9_000,
                    powertrain: "ice", usage: "commercial", buyer_jurisdiction: "OR")
      expect(quote.out_of_state_buyer?).to be(true)
      expect(described_class.lien_filing_required?(quote)).to be(true)
      expect(described_class.lien_filing_method(quote)).to eq("paper")
    end

    it "does not add a lien fee to the quote" do
      expect(item_pairs(input(financing: "loan"))).to eq([["registration", 5_850], ["ev_surcharge", 15_000]])
    end
  end

  describe "buyer jurisdiction" do
    it "normalizes the buyer jurisdiction but does not change fees or tags" do
      quote = input(buyer_jurisdiction: " or ")
      expect(quote.buyer_jurisdiction).to eq("OR")
      expect(quote.out_of_state_buyer?).to be(true)
      expect(described_class.total_cents(quote)).to eq(20_850)
      expect(described_class.temp_tag_valid_days(quote)).to eq(45)
    end
  end
end
