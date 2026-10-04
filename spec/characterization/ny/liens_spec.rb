require "rails_helper"

RSpec.describe Jurisdictions::NewYork, "lien filing (characterization)" do
  no_lien_reason = "No lien to record"
  electronic_reason = "Electronic filing via New York ELT"
  paper_reason = "Paper filing with New York motor vehicle agency"

  def input(**attributes)
    Jurisdictions::QuoteInput.new({
      jurisdiction: "NY",
      weight_lbs: 4_000,
      purchase_price_cents: 5_000_000,
      delivery_date: Date.new(2025, 6, 10)
    }.merge(attributes))
  end

  def determination(**attributes)
    quote = input(**attributes)
    [
      described_class.lien_filing_required?(quote),
      described_class.lien_filing_method(quote),
      described_class.lien_reason(quote)
    ]
  end

  it "defaults financing to cash and lienholder ELT to true" do
    expect(Jurisdictions::QuoteInput.new.financing).to eq("cash")
    expect(Jurisdictions::QuoteInput.new.lienholder_elt).to be(true)
    expect(determination).to eq([false, nil, no_lien_reason])
  end

  describe "financing and lienholder ELT matrix" do
    {
      ["cash", true] => [false, nil, no_lien_reason],
      ["cash", false] => [false, nil, no_lien_reason],
      ["cash", nil] => [false, nil, no_lien_reason],
      ["loan", true] => [true, "electronic", electronic_reason],
      ["loan", false] => [true, "paper", paper_reason],
      ["loan", nil] => [true, "paper", paper_reason],
      ["lease", true] => [false, nil, no_lien_reason],
      ["lease", false] => [false, nil, no_lien_reason],
      ["lease", nil] => [false, nil, no_lien_reason],
      ["refinance", true] => [true, "paper", paper_reason],
      ["refinance", false] => [true, "paper", paper_reason],
      ["refinance", nil] => [true, "paper", paper_reason]
    }.each do |(financing, elt), expected|
      it "returns #{expected.inspect} for #{financing} with lienholder_elt #{elt.inspect}" do
        expect(determination(financing: financing, lienholder_elt: elt)).to eq(expected)
      end
    end

    it "uses electronic_reason filing for a loan when lienholder_elt is omitted" do
      expect(determination(financing: "loan")).to eq([true, "electronic", electronic_reason])
    end

    it "uses paper_reason filing for a refinance when lienholder_elt is omitted" do
      expect(determination(financing: "refinance")).to eq([true, "paper", paper_reason])
    end
  end

  describe "financing values outside the supported set" do
    [nil, "", "LOAN", "Loan", " loan", "loan ", "REFINANCE", "Lease", "finance", "credit"].each do |financing|
      it "does not require a lien for #{financing.inspect}" do
        expect(determination(financing: financing)).to eq([false, nil, no_lien_reason])
      end
    end
  end

  describe "lienholder_elt casting" do
    [false, "false", "FALSE", "0", 0, "f", "off"].each do |value|
      it "files a loan on paper_reason when lienholder_elt is #{value.inspect}" do
        expect(input(lienholder_elt: value).lienholder_elt).to be(false)
        expect(determination(financing: "loan", lienholder_elt: value)).to eq([true, "paper", paper_reason])
      end
    end

    [true, "true", "1", 1, "yes", "no", "n", "anything"].each do |value|
      it "files a loan electronically when lienholder_elt is #{value.inspect}" do
        expect(input(lienholder_elt: value).lienholder_elt).to be(true)
        expect(determination(financing: "loan", lienholder_elt: value)).to eq([true, "electronic", electronic_reason])
      end
    end

    it "casts an empty string to nil and files a loan on paper" do
      expect(input(lienholder_elt: "").lienholder_elt).to be_nil
      expect(determination(financing: "loan", lienholder_elt: "")).to eq([true, "paper", paper_reason])
    end
  end

  describe "inputs that do not affect lien determination" do
    it "ignores buyer jurisdiction, usage, powertrain, county, weight, price, and delivery date" do
      [
        { buyer_jurisdiction: "NJ" },
        { usage: "commercial" },
        { powertrain: "ice" },
        { county: "KINGS" },
        { weight_lbs: nil },
        { purchase_price_cents: nil },
        { delivery_date: nil },
        { jurisdiction: "CA" }
      ].each do |attributes|
        expect(determination(financing: "loan", **attributes)).to eq([true, "electronic", electronic_reason])
        expect(determination(financing: "refinance", **attributes)).to eq([true, "paper", paper_reason])
        expect(determination(financing: "lease", **attributes)).to eq([false, nil, no_lien_reason])
      end
    end
  end

  describe LienFilings::DeterminationService do
    it "returns the NY determination for an input with only lien fields" do
      quote = Jurisdictions::QuoteInput.new(jurisdiction: "ny", financing: "loan", lienholder_elt: true)
      result = described_class.call(quote)

      expect(result.jurisdiction).to eq(Jurisdictions::NewYork)
      expect(result.required).to be(true)
      expect(result.filing_method).to eq("electronic")
      expect(result.reason).to eq(electronic_reason)
    end

    it "returns paper_reason for a refinance with ELT available" do
      result = described_class.call(Jurisdictions::QuoteInput.new(jurisdiction: "NY", financing: "refinance", lienholder_elt: true))

      expect([result.required, result.filing_method, result.reason]).to eq([true, "paper", paper_reason])
    end

    it "returns no lien for a lease" do
      result = described_class.call(Jurisdictions::QuoteInput.new(jurisdiction: "NY", financing: "lease"))

      expect([result.required, result.filing_method, result.reason]).to eq([false, nil, no_lien_reason])
    end
  end
end
