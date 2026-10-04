require "rails_helper"

RSpec.describe "Florida rules through domain services" do
  let!(:customer) do
    CustomerAccounts::Customer.create!(
      customer_number: "LC-FLCHAR-1",
      first_name: "Rowan",
      last_name: "Ellis",
      email: "rowan.flchar@example.test",
      jurisdiction_code: "FL"
    )
  end
  let!(:vehicle) do
    CustomerAccounts::Vehicle.create!(
      customer: customer,
      vin: "5LVFLCHAR00000001",
      model: "Air Touring",
      model_year: 2025,
      weight_lbs: 4_999,
      purchase_price_cents: 4_899_000,
      powertrain: "bev",
      financing: "loan",
      lienholder_elt: true,
      usage: "personal",
      delivery_date: Date.new(2025, 6, 10)
    )
  end

  describe Registrations::FeeCalculator do
    it "snapshots the Florida line items and totals" do
      result = described_class.call(vehicle: vehicle)

      expect(result.jurisdiction).to eq(Jurisdictions::Florida)
      expect(result.line_items.map(&:to_h)).to eq([
        { code: "registration", label: "Registration", amount_cents: 4_685 },
        { code: "weight_fee", label: "Weight fee", amount_cents: 6_749 }
      ])
      expect(result.registration_fee_cents).to eq(11_434)
      expect(result.ev_surcharge_cents).to eq(0)
      expect(result.total_cents).to eq(11_434)
      expect(result.input.buyer_jurisdiction).to eq("FL")
    end

    it "moves to the top tier at 5,000 lbs" do
      vehicle.update!(weight_lbs: 5_000)

      expect(described_class.call(vehicle: vehicle).total_cents).to eq(13_990)
    end
  end

  describe TempTags::IssueService do
    it "issues a 30-day tag expiring 29 days after the issue date" do
      tag = described_class.call(vehicle: vehicle, issue_date: Date.new(2025, 6, 10))

      expect(tag.jurisdiction_code).to eq("FL")
      expect(tag.tag_number).to match(/\AFL-T-\d{6}\z/)
      expect(tag.valid_days).to eq(30)
      expect(tag.issued_on).to eq(Date.new(2025, 6, 10))
      expect(tag.expires_on).to eq(Date.new(2025, 7, 9))
    end

    it "keeps 30 days for an out-of-state buyer and commercial use" do
      tag = described_class.call(vehicle: vehicle, issue_date: Date.new(2024, 1, 31), buyer_jurisdiction: "GA", usage: "commercial")

      expect(tag.valid_days).to eq(30)
      expect(tag.expires_on).to eq(Date.new(2024, 2, 29))
    end

    it "offsets the rule expiry by the difference when valid_days is overridden" do
      tag = described_class.call(vehicle: vehicle, issue_date: Date.new(2025, 6, 10), valid_days: 45)

      expect(tag.valid_days).to eq(45)
      expect(tag.expires_on).to eq(Date.new(2025, 7, 24))
    end
  end

  describe TexasInTransitOverride do
    let(:host) { Class.new { include TexasInTransitOverride }.new }

    it "returns the Florida rule days for in-state and out-of-state buyers" do
      [nil, "FL", "TX", "GA"].each do |buyer|
        input = Jurisdictions::QuoteInput.new(jurisdiction: "FL", buyer_jurisdiction: buyer, delivery_date: Date.new(2025, 6, 10))
        expect(host.temp_tag_days_for(Jurisdictions::Florida, input)).to eq(30)
      end
    end
  end

  describe LienFilings::DeterminationService do
    def determine(**attributes)
      result = described_class.call(Jurisdictions::QuoteInput.new({ jurisdiction: "FL" }.merge(attributes)))
      [result.jurisdiction, result.required, result.filing_method, result.reason]
    end

    it "determines each financing type for ELT and non-ELT lienholders" do
      fl = Jurisdictions::Florida
      expect(determine(financing: "loan", lienholder_elt: true)).to eq([fl, true, "electronic", "Electronic filing via Florida ELT"])
      expect(determine(financing: "refinance", lienholder_elt: true)).to eq([fl, true, "electronic", "Electronic filing via Florida ELT"])
      expect(determine(financing: "loan", lienholder_elt: false)).to eq([fl, true, "paper", "Paper filing with Florida motor vehicle agency"])
      expect(determine(financing: "refinance", lienholder_elt: false)).to eq([fl, true, "paper", "Paper filing with Florida motor vehicle agency"])
      expect(determine(financing: "lease", lienholder_elt: true)).to eq([fl, false, nil, "No lien to record"])
      expect(determine(financing: "lease", lienholder_elt: false)).to eq([fl, false, nil, "No lien to record"])
      expect(determine(financing: "cash", lienholder_elt: true)).to eq([fl, false, nil, "No lien to record"])
    end

    it "records no lien for a financed out-of-state buyer" do
      expect(determine(financing: "loan", buyer_jurisdiction: "GA")).to eq([Jurisdictions::Florida, false, nil, "No lien to record"])
    end

    it "resolves the jurisdiction from a lowercase input code" do
      expect(determine(jurisdiction: "fl", financing: "loan").first(3)).to eq([Jurisdictions::Florida, true, "electronic"])
    end
  end
end
