require "rails_helper"

RSpec.describe Jurisdictions::NewYork, "temporary tags (characterization)" do
  def input(**attributes)
    Jurisdictions::QuoteInput.new({
      jurisdiction: "NY",
      weight_lbs: 4_000,
      purchase_price_cents: 5_000_000,
      delivery_date: Date.new(2025, 6, 10)
    }.merge(attributes))
  end

  describe "temp_tag_valid_days" do
    it "returns 30 days when buyer jurisdiction is omitted (defaults to the jurisdiction)" do
      expect(input.buyer_jurisdiction).to eq("NY")
      expect(described_class.temp_tag_valid_days(input)).to eq(30)
    end

    ["NY", "ny", " Ny ", "", "  ", nil].each do |buyer|
      it "returns 30 days for buyer jurisdiction #{buyer.inspect}" do
        expect(described_class.temp_tag_valid_days(input(buyer_jurisdiction: buyer))).to eq(30)
      end
    end

    %w[NJ nj CA ON PA ZZ NYC].each do |buyer|
      it "returns 10 days for buyer jurisdiction #{buyer.inspect}" do
        expect(described_class.temp_tag_valid_days(input(buyer_jurisdiction: buyer))).to eq(10)
      end
    end

    it "compares the buyer with the input jurisdiction, not with NY" do
      expect(described_class.temp_tag_valid_days(input(jurisdiction: "CA"))).to eq(30)
      expect(described_class.temp_tag_valid_days(input(jurisdiction: "CA", buyer_jurisdiction: "CA"))).to eq(30)
      expect(described_class.temp_tag_valid_days(input(jurisdiction: "CA", buyer_jurisdiction: "NY"))).to eq(10)
      expect(described_class.temp_tag_valid_days(input(jurisdiction: nil))).to eq(30)
      expect(described_class.temp_tag_valid_days(input(jurisdiction: nil, buyer_jurisdiction: "NY"))).to eq(10)
      expect(described_class.temp_tag_valid_days(input(jurisdiction: " ny ", buyer_jurisdiction: "NY"))).to eq(30)
    end

    it "ignores usage, financing, powertrain, weight, price, county, and delivery date" do
      [
        { usage: "commercial" },
        { financing: "loan" },
        { financing: "lease" },
        { financing: "refinance" },
        { powertrain: "ice" },
        { weight_lbs: nil },
        { purchase_price_cents: nil },
        { county: "KINGS" },
        { delivery_date: nil }
      ].each do |attributes|
        expect(described_class.temp_tag_valid_days(input(**attributes))).to eq(30)
        expect(described_class.temp_tag_valid_days(input(buyer_jurisdiction: "NJ", **attributes))).to eq(10)
      end
    end

    it "does not use TEMP_TAG_DAYS for out-of-state buyers, though metadata reports it" do
      expect(described_class.metadata[:temp_tag_days]).to eq(30)
      expect(described_class.temp_tag_valid_days(input(buyer_jurisdiction: "NJ"))).to eq(10)
    end
  end

  describe "temp_tag_expires_on" do
    {
      Date.new(2025, 6, 10) => Date.new(2025, 7, 10),
      Date.new(2025, 1, 1) => Date.new(2025, 1, 31),
      Date.new(2025, 1, 2) => Date.new(2025, 2, 1),
      Date.new(2025, 1, 31) => Date.new(2025, 3, 2),
      Date.new(2024, 1, 31) => Date.new(2024, 3, 1),
      Date.new(2024, 1, 30) => Date.new(2024, 2, 29),
      Date.new(2024, 2, 29) => Date.new(2024, 3, 30),
      Date.new(2025, 12, 1) => Date.new(2025, 12, 31),
      Date.new(2025, 12, 2) => Date.new(2026, 1, 1)
    }.each do |delivery, expiry|
      it "expires in-state tags delivered #{delivery} on #{expiry}" do
        quote = input(delivery_date: delivery)
        expect(described_class.temp_tag_expires_on(quote)).to eq(expiry)
        expect(described_class.temp_tag_expires_on(quote) - delivery).to eq(30)
      end
    end

    {
      Date.new(2025, 6, 10) => Date.new(2025, 6, 20),
      Date.new(2025, 6, 20) => Date.new(2025, 6, 30),
      Date.new(2025, 6, 21) => Date.new(2025, 7, 1),
      Date.new(2025, 2, 18) => Date.new(2025, 2, 28),
      Date.new(2025, 2, 19) => Date.new(2025, 3, 1),
      Date.new(2024, 2, 19) => Date.new(2024, 2, 29),
      Date.new(2024, 2, 20) => Date.new(2024, 3, 1),
      Date.new(2025, 12, 21) => Date.new(2025, 12, 31),
      Date.new(2025, 12, 22) => Date.new(2026, 1, 1)
    }.each do |delivery, expiry|
      it "expires out-of-state tags delivered #{delivery} on #{expiry}" do
        quote = input(delivery_date: delivery, buyer_jurisdiction: "NJ")
        expect(described_class.temp_tag_expires_on(quote)).to eq(expiry)
        expect(described_class.temp_tag_expires_on(quote) - delivery).to eq(10)
      end
    end

    it "casts ISO date strings" do
      expect(described_class.temp_tag_expires_on(input(delivery_date: "2025-06-10"))).to eq(Date.new(2025, 7, 10))
    end

    it "parses slash dates day-first" do
      expect(input(delivery_date: "06/10/2025").delivery_date).to eq(Date.new(2025, 10, 6))
      expect(described_class.temp_tag_expires_on(input(delivery_date: "06/10/2025"))).to eq(Date.new(2025, 11, 5))
    end

    it "raises NoMethodError when delivery date is missing or invalid" do
      expect(input(delivery_date: "2025-02-30").delivery_date).to be_nil
      expect { described_class.temp_tag_expires_on(input(delivery_date: nil)) }.to raise_error(NoMethodError, /undefined method `\+'/)
      expect { described_class.temp_tag_expires_on(input(delivery_date: "2025-02-30")) }.to raise_error(NoMethodError)
      expect { described_class.temp_tag_expires_on(input(delivery_date: "not a date")) }.to raise_error(NoMethodError)
    end
  end
end
