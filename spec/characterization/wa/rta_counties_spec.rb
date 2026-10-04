require "rails_helper"

RSpec.describe "Washington RTA counties outside the jurisdictions directory" do
  describe CustomerAccounts::Vehicle do
    it "declares the WA RTA counties as a frozen, uppercase list" do
      expect(described_class::WA_RTA_COUNTIES).to eq(%w[KING PIERCE SNOHOMISH])
      expect(described_class::WA_RTA_COUNTIES).to be_frozen
    end
  end

  describe "vehicle-backed Washington services" do
    let(:customer) do
      CustomerAccounts::Customer.create!(
        customer_number: "CHAR-WA-0001",
        first_name: "Wren",
        last_name: "Tester",
        email: "wren.char-wa@example.test",
        jurisdiction_code: "WA"
      )
    end

    def vehicle(county:, **attributes)
      customer.vehicles.create!({
        vin: "5LUCDA1B2WA#{format('%06d', CustomerAccounts::Vehicle.count + 1)}",
        model: "Air Touring",
        model_year: 2025,
        weight_lbs: 4_200,
        purchase_price_cents: 4_899_000,
        powertrain: "bev",
        financing: "cash",
        lienholder_elt: true,
        usage: "personal",
        county: county,
        delivery_date: Date.new(2025, 6, 10)
      }.merge(attributes))
    end

    def fee_pairs(result)
      result.line_items.map { |item| [item.code, item.amount_cents] }
    end

    CustomerAccounts::Vehicle::WA_RTA_COUNTIES.each do |county|
      it "Registrations::FeeCalculator adds RTA tax for a #{county} vehicle" do
        result = Registrations::FeeCalculator.call(vehicle: vehicle(county: county))
        expect(result.jurisdiction).to eq(Jurisdictions::Washington)
        expect(fee_pairs(result)).to eq([["registration", 5_850], ["rta_tax", 53_889], ["ev_surcharge", 15_000]])
        expect(result.registration_fee_cents).to eq(59_739)
        expect(result.ev_surcharge_cents).to eq(15_000)
        expect(result.total_cents).to eq(74_739)
      end
    end

    it "Registrations::FeeCalculator matches a lowercase stored RTA county" do
      result = Registrations::FeeCalculator.call(vehicle: vehicle(county: "king"))
      expect(result.input.county).to eq("KING")
      expect(result.total_cents).to eq(74_739)
    end

    [["SPOKANE"], ["THURSTON"], [nil]].each do |(county)|
      it "Registrations::FeeCalculator adds no RTA tax for county #{county.inspect}" do
        result = Registrations::FeeCalculator.call(vehicle: vehicle(county: county))
        expect(fee_pairs(result)).to eq([["registration", 5_850], ["ev_surcharge", 15_000]])
        expect(result.registration_fee_cents).to eq(5_850)
        expect(result.total_cents).to eq(20_850)
      end
    end

    it "Registrations::FeeCalculator uses the vehicle's powertrain, weight and price" do
      result = Registrations::FeeCalculator.call(
        vehicle: vehicle(county: "SNOHOMISH", powertrain: "phev", weight_lbs: 6_500, purchase_price_cents: 10_000_000)
      )
      expect(fee_pairs(result)).to eq([["registration", 9_600], ["rta_tax", 110_000], ["ev_surcharge", 7_500]])
      expect(result.total_cents).to eq(127_100)
    end

    it "TempTags::IssueService issues RTA and non-RTA vehicles with the same validity" do
      rta_tag = TempTags::IssueService.call(vehicle: vehicle(county: "KING"), issue_date: Date.new(2025, 6, 10))
      other_tag = TempTags::IssueService.call(vehicle: vehicle(county: "SPOKANE"), issue_date: Date.new(2025, 6, 10))
      [rta_tag, other_tag].each do |tag|
        expect(tag.jurisdiction_code).to eq("WA")
        expect(tag.valid_days).to eq(45)
        expect(tag.expires_on).to eq(Date.new(2025, 7, 25))
      end
    end

    it "TempTags::IssueService issues 20-day tags for commercial vehicles" do
      tag = TempTags::IssueService.call(vehicle: vehicle(county: "PIERCE", usage: "commercial"), issue_date: Date.new(2025, 6, 10))
      expect(tag.valid_days).to eq(20)
      expect(tag.expires_on).to eq(Date.new(2025, 6, 30))
    end

    it "TempTags::IssueService shifts expiry by an overridden validity" do
      tag = TempTags::IssueService.call(vehicle: vehicle(county: "KING"), issue_date: Date.new(2025, 6, 10), valid_days: 30)
      expect(tag.valid_days).to eq(30)
      expect(tag.expires_on).to eq(Date.new(2025, 7, 10))
    end

    it "LienFilings::DeterminationService is independent of county" do
      %w[KING SPOKANE].each do |county|
        input = Jurisdictions::QuoteInput.new(jurisdiction: "WA", financing: "lease", lienholder_elt: false, county: county)
        result = LienFilings::DeterminationService.call(input)
        expect(result.jurisdiction).to eq(Jurisdictions::Washington)
        expect(result.required).to be(true)
        expect(result.filing_method).to eq("paper")
        expect(result.reason).to eq("Paper filing with Washington motor vehicle agency")
      end
    end
  end
end
