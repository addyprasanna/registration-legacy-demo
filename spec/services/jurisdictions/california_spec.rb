require "rails_helper"

RSpec.describe Jurisdictions::California do
  def input(**attributes)
    Jurisdictions::QuoteInput.new({
      jurisdiction: "CA",
      weight_lbs: 4_200,
      purchase_price_cents: 4_899_000,
      delivery_date: Date.new(2025, 6, 10)
    }.merge(attributes))
  end

  it "calculates registration weight boundaries" do
    expect(described_class.registration_fee_cents(input(weight_lbs: 2_999))).to eq(6_500)
    expect(described_class.registration_fee_cents(input(weight_lbs: 3_000))).to eq(8_500)
    expect(described_class.registration_fee_cents(input(weight_lbs: 4_500))).to eq(11_000)
    expect(described_class.registration_fee_cents(input(weight_lbs: 6_000))).to eq(15_000)
  end

  it "applies battery-electric and plug-in hybrid surcharges" do
    expect(described_class.ev_surcharge_cents(input(powertrain: "bev"))).to eq(10_000)
    expect(described_class.ev_surcharge_cents(input(powertrain: "phev"))).to eq(5_000)
    expect(described_class.ev_surcharge_cents(input(powertrain: "ice"))).to eq(0)
  end

  it "adds county fees when a county is supplied" do
    expect(described_class.registration_fee_cents(input(county: "los angeles"))).to eq(10_000)
  end

  it "adds a commercial plate and reduces tag validity for commercial use" do
    quote = input(usage: "commercial")
    expect(described_class.fee_line_items(quote).map(&:code)).to include("commercial_plate")
    expect(described_class.temp_tag_valid_days(quote)).to eq(60)
  end

  it "sets the default temporary tag expiration date" do
    expect(described_class.temp_tag_expires_on(input)).to eq(Date.new(2025, 9, 8))
  end

  it "requires lien filing for loans and refinances but not leases" do
    expect(described_class.lien_filing_required?(input(financing: "loan"))).to be(true)
    expect(described_class.lien_filing_required?(input(financing: "refinance"))).to be(true)
    expect(described_class.lien_filing_required?(input(financing: "lease"))).to be(false)
  end
end
