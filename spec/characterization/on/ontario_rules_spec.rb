require "rails_helper"
require "ostruct"

RSpec.describe OntarioRules, "characterization" do
  let(:host_class) do
    Struct.new(:vehicle_weight_lbs, :price_cents, :delivery_date, :financing, keyword_init: true) do
      include OntarioRules
    end
  end

  def host(**attributes)
    host_class.new(**{ vehicle_weight_lbs: 4_200, price_cents: 4_899_000, delivery_date: Date.new(2025, 6, 10), financing: "cash" }.merge(attributes))
  end

  it "defines the Ontario constants" do
    expect(OntarioRules::ONTARIO_FX_RATE).to eq(BigDecimal("1.35"))
    expect(OntarioRules::ONTARIO_RST_RATE).to eq(BigDecimal("0.025"))
    expect(OntarioRules::ONTARIO_EV_SURCHARGE_CENTS).to eq(5_000)
    expect(OntarioRules::ONTARIO_TEMP_TAG_DAYS).to eq(40)
  end

  describe "#ontario_price_cents_cad" do
    { 0 => "0", 1_000 => "1350", 4_899_000 => "6613650", 15 => "20.25", -1_000 => "-1350" }.each do |price, cad|
      it "converts #{price} cents to #{cad} as a BigDecimal" do
        value = host(price_cents: price).ontario_price_cents_cad
        expect(value).to be_a(BigDecimal)
        expect(value).to eq(BigDecimal(cad))
      end
    end

    it "accepts a numeric string price" do
      expect(host(price_cents: "1000").ontario_price_cents_cad).to eq(BigDecimal("1350"))
    end

    it "raises ArgumentError for a nil price" do
      expect { host(price_cents: nil).ontario_price_cents_cad }.to raise_error(ArgumentError)
    end
  end

  describe "#ontario_rst_component_cents" do
    {
      -1_000 => -34,
      0 => 0,
      14 => 0,
      15 => 1,
      400 => 14,
      1_200 => 40,
      2_000 => 68,
      4_899_000 => 165_341,
      1_000_000_000 => 33_750_000
    }.each do |price, rst|
      it "returns #{rst} for #{price} cents" do
        expect(host(price_cents: price).ontario_rst_component_cents).to eq(rst)
      end
    end
  end

  describe "#ontario_registration_fee_cents" do
    {
      nil => 12_000,
      -1 => 12_000,
      0 => 5_900,
      3_299 => 5_900,
      3_300 => 9_000,
      5_499 => 9_000,
      5_500 => 12_000,
      20_000 => 12_000
    }.each do |weight, base|
      it "returns base #{base} plus RST for weight #{weight.inspect}" do
        expect(host(vehicle_weight_lbs: weight, price_cents: 0).ontario_registration_fee_cents).to eq(base)
        expect(host(vehicle_weight_lbs: weight, price_cents: 1_200).ontario_registration_fee_cents).to eq(base + 40)
      end
    end

    it "treats a fractional weight just under 3300 as the first tier" do
      expect(host(vehicle_weight_lbs: 3_299.9, price_cents: 0).ontario_registration_fee_cents).to eq(5_900)
    end

    it "subtracts negative RST from the base" do
      expect(host(vehicle_weight_lbs: 4_200, price_cents: -1_000).ontario_registration_fee_cents).to eq(8_966)
    end

    it "falls through to the top tier when the weight is a string" do
      expect(host(vehicle_weight_lbs: "100", price_cents: 0).ontario_registration_fee_cents).to eq(12_000)
      expect(host(vehicle_weight_lbs: "4200", price_cents: 0).ontario_registration_fee_cents).to eq(12_000)
    end
  end

  describe "#ontario_ev_surcharge_cents" do
    it "always returns 5000" do
      expect(host.ontario_ev_surcharge_cents).to eq(5_000)
    end
  end

  describe "#ontario_temp_tag_valid_days and #ontario_temp_tag_expires_on" do
    it "returns 40 days" do
      expect(host.ontario_temp_tag_valid_days).to eq(40)
    end

    {
      Date.new(2025, 6, 10) => Date.new(2025, 7, 20),
      Date.new(2024, 2, 20) => Date.new(2024, 3, 31),
      Date.new(2023, 2, 20) => Date.new(2023, 4, 1),
      Date.new(2024, 12, 25) => Date.new(2025, 2, 3)
    }.each do |delivery_date, expires_on|
      it "expires a tag delivered #{delivery_date} on #{expires_on}" do
        expect(host(delivery_date: delivery_date).ontario_temp_tag_expires_on).to eq(expires_on)
      end
    end

    it "raises NoMethodError when delivery_date is nil" do
      expect { host(delivery_date: nil).ontario_temp_tag_expires_on }.to raise_error(NoMethodError)
    end
  end

  describe "#ontario_lien_filing_method" do
    { "cash" => nil, "loan" => "electronic", "lease" => "electronic", "refinance" => "electronic", nil => nil, "LOAN" => nil, "other" => nil }.each do |financing, method|
      it "returns #{method.inspect} for financing #{financing.inspect}" do
        expect(host(financing: financing).ontario_lien_filing_method).to eq(method)
      end
    end
  end

  describe "#ontario_round" do
    {
      0.5 => 0,
      1.5 => 2,
      2.5 => 2,
      2.4999 => 2,
      2.5001 => 3,
      13.5 => 14,
      40.5 => 40,
      -0.5 => 0,
      -1.5 => -2,
      -33.75 => -34,
      BigDecimal("67.5") => 68,
      "2.5" => 2,
      7 => 7
    }.each do |amount, rounded|
      it "rounds #{amount.inspect} to #{rounded} (half-even)" do
        expect(host.ontario_round(amount)).to eq(rounded)
      end
    end

    it "returns an Integer" do
      expect(host.ontario_round(BigDecimal("1.5"))).to be_an(Integer)
    end
  end

  describe "usage through an OpenStruct wrapper (as Jurisdictions::Ontario does)" do
    it "computes registration fee, RST and expiry" do
      wrapper = OpenStruct.new(vehicle_weight_lbs: 3_300, price_cents: 400, delivery_date: Date.new(2024, 2, 20))
      wrapper.extend(OntarioRules)

      expect(wrapper.ontario_rst_component_cents).to eq(14)
      expect(wrapper.ontario_registration_fee_cents).to eq(9_014)
      expect(wrapper.ontario_temp_tag_expires_on).to eq(Date.new(2024, 3, 31))
      expect(wrapper.ontario_lien_filing_method).to be_nil
    end
  end
end
