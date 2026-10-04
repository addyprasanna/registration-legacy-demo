require "rails_helper"

RSpec.describe Jurisdictions::NewYork, "metadata and registry (characterization)" do
  it "is registered under NY and resolved case- and whitespace-insensitively" do
    expect(Jurisdictions::Registry::CLASSES["NY"]).to eq(described_class)
    expect(Jurisdictions.for("NY")).to eq(described_class)
    expect(Jurisdictions.for(" ny ")).to eq(described_class)
    expect(described_class.code).to eq("NY")
  end

  it "exposes identity attributes" do
    expect(described_class.display_name).to eq("New York")
    expect(described_class.country).to eq("US")
    expect(described_class.currency).to eq("USD")
    expect(described_class.tier).to eq(1)
  end

  it "exposes the weight tiers and their labels" do
    expect(described_class.weight_tiers).to eq([[3_499, 3_250], [5_499, 5_180], [nil, 7_725]])
    expect(described_class.weight_tier_label(0)).to eq("1–3499 lbs")
    expect(described_class.weight_tier_label(1)).to eq("1–3499 lbs")
    expect(described_class.weight_tier_label(3_499)).to eq("1–3499 lbs")
    expect(described_class.weight_tier_label(3_500)).to eq("3500–5499 lbs")
    expect(described_class.weight_tier_label(5_499)).to eq("3500–5499 lbs")
    expect(described_class.weight_tier_label(5_500)).to eq("Over 5499 lbs")
  end

  it "exposes title, ELT, and lease lien settings" do
    expect(described_class.title_fee_cents).to eq(5_000)
    expect(described_class.elt_available?).to be(true)
    expect(described_class.lease_lien_required?).to be(false)
  end

  it "lists the MCTD counties in upper case" do
    expect(described_class::MCTD_COUNTIES).to eq(
      ["NEW YORK", "KINGS", "QUEENS", "BRONX", "RICHMOND", "NASSAU", "SUFFOLK", "WESTCHESTER"]
    )
  end

  it "exposes declared constants that the calculations do not all read" do
    expect(described_class::TEMP_TAG_DAYS).to eq(30)
    expect(described_class::EV_SURCHARGE_CENTS).to eq(7_500)
    expect(described_class::AD_VALOREM_RATE).to eq(BigDecimal("0.0045"))
  end

  it "returns the metadata hash" do
    expect(described_class.metadata).to eq(
      code: "NY",
      name: "New York",
      country: "US",
      currency: "USD",
      tier: 1,
      weight_tiers: [[3_499, 3_250], [5_499, 5_180], [nil, 7_725]],
      ev_surcharge_cents: 7_500,
      temp_tag_days: 30,
      elt: true
    )
  end
end
