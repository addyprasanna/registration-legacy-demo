require "rails_helper"

RSpec.describe Jurisdictions::NewYork, "registration fees (characterization)" do
  def input(**attributes)
    Jurisdictions::QuoteInput.new({
      jurisdiction: "NY",
      weight_lbs: 4_000,
      purchase_price_cents: 5_000_000,
      delivery_date: Date.new(2025, 6, 10)
    }.merge(attributes))
  end

  def items(**attributes)
    described_class.fee_line_items(input(**attributes)).map(&:to_h)
  end

  def amount(code, **attributes)
    described_class.fee_line_items(input(**attributes)).find { |item| item.code == code }&.amount_cents
  end

  describe "default input" do
    it "returns registration, ad valorem, and EV line items in order" do
      expect(items).to eq([
        { code: "registration", label: "Registration", amount_cents: 5_180 },
        { code: "ad_valorem", label: "Value-based tax", amount_cents: 22_500 },
        { code: "ev_surcharge", label: "EV surcharge", amount_cents: 7_500 }
      ])
    end

    it "splits registration fee, EV surcharge, and total" do
      expect(described_class.registration_fee_cents(input)).to eq(27_680)
      expect(described_class.ev_surcharge_cents(input)).to eq(7_500)
      expect(described_class.total_cents(input)).to eq(35_180)
    end
  end

  it "returns all four line items in order when every component applies" do
    expect(items(county: "KINGS", powertrain: "bev")).to eq([
      { code: "registration", label: "Registration", amount_cents: 5_180 },
      { code: "ad_valorem", label: "Value-based tax", amount_cents: 22_500 },
      { code: "county_fee", label: "MCTD fee", amount_cents: 5_000 },
      { code: "ev_surcharge", label: "EV surcharge", amount_cents: 7_500 }
    ])
    expect(described_class.registration_fee_cents(input(county: "KINGS"))).to eq(32_680)
    expect(described_class.ev_surcharge_cents(input(county: "KINGS"))).to eq(7_500)
    expect(described_class.total_cents(input(county: "KINGS"))).to eq(40_180)
  end

  it "returns only the registration line item when price is zero, no county, and ICE" do
    expect(items(purchase_price_cents: 0, powertrain: "ice")).to eq([
      { code: "registration", label: "Registration", amount_cents: 5_180 }
    ])
    expect(described_class.ev_surcharge_cents(input(purchase_price_cents: 0, powertrain: "ice"))).to eq(0)
    expect(described_class.total_cents(input(purchase_price_cents: 0, powertrain: "ice"))).to eq(5_180)
  end

  describe "weight tiers" do
    {
      -1 => 3_250,
      0 => 3_250,
      1 => 3_250,
      3_498 => 3_250,
      3_499 => 3_250,
      3_500 => 5_180,
      3_501 => 5_180,
      5_498 => 5_180,
      5_499 => 5_180,
      5_500 => 7_725,
      5_501 => 7_725,
      20_000 => 7_725,
      1_000_000 => 7_725
    }.each do |weight, fee|
      it "charges #{fee} cents for #{weight} lbs" do
        quote = input(weight_lbs: weight, purchase_price_cents: 0, powertrain: "ice")
        expect(described_class.registration_fee_cents(quote)).to eq(fee)
        expect(amount("registration", weight_lbs: weight)).to eq(fee)
      end
    end

    it "casts numeric strings and truncates decimal strings" do
      expect(input(weight_lbs: "3499").weight_lbs).to eq(3_499)
      expect(amount("registration", weight_lbs: "3499")).to eq(3_250)
      expect(input(weight_lbs: "3499.9").weight_lbs).to eq(3_499)
      expect(amount("registration", weight_lbs: "3499.9")).to eq(3_250)
      expect(amount("registration", weight_lbs: "3500")).to eq(5_180)
      expect(amount("registration", weight_lbs: 3_499.9)).to eq(3_250)
    end

    it "casts non-numeric strings to 0 and charges the lowest tier" do
      expect(input(weight_lbs: "abc").weight_lbs).to eq(0)
      expect(amount("registration", weight_lbs: "abc")).to eq(3_250)
    end

    it "raises NoMethodError when weight is nil" do
      expect { described_class.fee_line_items(input(weight_lbs: nil)) }.to raise_error(NoMethodError, /undefined method `<='/)
      expect { described_class.registration_fee_cents(input(weight_lbs: nil)) }.to raise_error(NoMethodError)
      expect { described_class.total_cents(input(weight_lbs: nil)) }.to raise_error(NoMethodError)
      expect { described_class.ev_surcharge_cents(input(weight_lbs: nil)) }.to raise_error(NoMethodError)
    end
  end

  describe "ad valorem tax (0.45% of price, half-up to whole cents)" do
    {
      0 => nil,
      1 => nil,
      111 => nil,
      112 => 1,
      333 => 1,
      334 => 2,
      1_000 => 5,
      3_000 => 14,
      999_999 => 4_500,
      5_000_000 => 22_500,
      1_000_000_000 => 4_500_000
    }.each do |price, tax|
      it "returns #{tax.inspect} for #{price} cents" do
        expect(amount("ad_valorem", purchase_price_cents: price)).to eq(tax)
      end
    end

    it "omits the line item when price is nil" do
      expect(input(purchase_price_cents: nil).price_cents).to eq(0)
      expect(amount("ad_valorem", purchase_price_cents: nil)).to be_nil
      expect(described_class.registration_fee_cents(input(purchase_price_cents: nil))).to eq(5_180)
    end

    it "omits the line item for negative prices" do
      expect(amount("ad_valorem", purchase_price_cents: -1_000_000)).to be_nil
      expect(described_class.registration_fee_cents(input(purchase_price_cents: -1_000_000))).to eq(5_180)
    end

    it "casts price strings to integers by truncation" do
      expect(input(purchase_price_cents: "12.7").purchase_price_cents).to eq(12)
      expect(amount("ad_valorem", purchase_price_cents: "12.7")).to be_nil
      expect(amount("ad_valorem", purchase_price_cents: "250000")).to eq(1_125)
    end

    it "is included in registration_fee_cents and total_cents" do
      expect(described_class.registration_fee_cents(input(purchase_price_cents: 1_000, powertrain: "ice"))).to eq(5_185)
      expect(described_class.total_cents(input(purchase_price_cents: 1_000, powertrain: "ice"))).to eq(5_185)
    end
  end

  describe "MCTD county fee" do
    ["NEW YORK", "KINGS", "QUEENS", "BRONX", "RICHMOND", "NASSAU", "SUFFOLK", "WESTCHESTER"].each do |county|
      it "charges 5000 cents for #{county}" do
        expect(amount("county_fee", county: county)).to eq(5_000)
      end
    end

    it "normalizes case and surrounding whitespace" do
      expect(input(county: " kings ").county).to eq("KINGS")
      expect(amount("county_fee", county: " kings ")).to eq(5_000)
      expect(amount("county_fee", county: "new york")).to eq(5_000)
      expect(amount("county_fee", county: "Westchester")).to eq(5_000)
    end

    ["NEWYORK", "New York County", "NEW  YORK", "ALBANY", "ERIE", "LOS ANGELES"].each do |county|
      it "charges nothing for #{county.inspect}" do
        expect(amount("county_fee", county: county)).to be_nil
      end
    end

    it "charges nothing when county is nil, empty, or blank" do
      expect(amount("county_fee", county: nil)).to be_nil
      expect(input(county: "").county).to be_nil
      expect(amount("county_fee", county: "")).to be_nil
      expect(input(county: "   ").county).to be_nil
      expect(amount("county_fee", county: "   ")).to be_nil
    end

    it "is charged regardless of buyer jurisdiction" do
      expect(amount("county_fee", county: "QUEENS", buyer_jurisdiction: "NJ")).to eq(5_000)
    end

    it "is included in registration_fee_cents" do
      expect(described_class.registration_fee_cents(input(county: "BRONX"))).to eq(32_680)
    end
  end

  describe "EV surcharge" do
    it "defaults powertrain to bev" do
      expect(Jurisdictions::QuoteInput.new.powertrain).to eq("bev")
      expect(described_class.ev_surcharge_cents(input)).to eq(7_500)
    end

    {
      "bev" => 7_500,
      "phev" => 3_750,
      "ice" => 0,
      nil => 0,
      "" => 0,
      "BEV" => 0,
      "PHEV" => 0,
      " bev" => 0,
      "hybrid" => 0
    }.each do |powertrain, surcharge|
      it "returns #{surcharge} cents for powertrain #{powertrain.inspect}" do
        expect(described_class.ev_surcharge_cents(input(powertrain: powertrain))).to eq(surcharge)
        expect(amount("ev_surcharge", powertrain: powertrain)).to eq(surcharge.positive? ? surcharge : nil)
      end
    end

    it "is excluded from registration_fee_cents and included in total_cents" do
      expect(described_class.registration_fee_cents(input(powertrain: "phev"))).to eq(27_680)
      expect(described_class.total_cents(input(powertrain: "phev"))).to eq(31_430)
      expect(described_class.registration_fee_cents(input(powertrain: "ice"))).to eq(27_680)
      expect(described_class.total_cents(input(powertrain: "ice"))).to eq(27_680)
    end
  end

  describe "inputs that do not affect fees" do
    it "ignores usage" do
      expect(items(usage: "commercial")).to eq(items(usage: "personal"))
      expect(items(usage: nil)).to eq(items)
    end

    it "ignores financing and lienholder ELT" do
      %w[cash loan lease refinance].each do |financing|
        expect(items(financing: financing, lienholder_elt: false)).to eq(items)
      end
    end

    it "ignores buyer jurisdiction, jurisdiction, and delivery date" do
      expect(items(buyer_jurisdiction: "NJ")).to eq(items)
      expect(items(jurisdiction: "CA")).to eq(items)
      expect(items(jurisdiction: nil)).to eq(items)
      expect(items(delivery_date: nil)).to eq(items)
    end
  end
end
