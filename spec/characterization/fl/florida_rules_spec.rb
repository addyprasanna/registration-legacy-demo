require "rails_helper"

RSpec.describe Jurisdictions::Florida do
  def input(**attributes)
    Jurisdictions::QuoteInput.new({
      jurisdiction: "FL",
      weight_lbs: 4_200,
      purchase_price_cents: 4_899_000,
      delivery_date: Date.new(2025, 6, 10)
    }.merge(attributes))
  end

  describe "identity and constants" do
    it "is registered under FL with Tier 1 US/USD metadata" do
      expect(Jurisdictions.for("FL")).to eq(described_class)
      expect(Jurisdictions.for(" fl ")).to eq(described_class)
      expect(described_class.code).to eq("FL")
      expect(described_class.display_name).to eq("Florida")
      expect(described_class.country).to eq("US")
      expect(described_class.currency).to eq("USD")
      expect(described_class.tier).to eq(1)
    end

    it "exposes the weight tiers and metadata" do
      expect(described_class.weight_tiers).to eq([[2_499, 2_760], [3_499, 4_035], [4_999, 4_685], [nil, 7_240]])
      expect(described_class.metadata).to eq(
        code: "FL",
        name: "Florida",
        country: "US",
        currency: "USD",
        tier: 1,
        weight_tiers: [[2_499, 2_760], [3_499, 4_035], [4_999, 4_685], [nil, 7_240]],
        ev_surcharge_cents: 0,
        temp_tag_days: 30,
        elt: true
      )
    end

    it "labels weight tiers at each edge" do
      expect(described_class.weight_tier_label(0)).to eq("1–2499 lbs")
      expect(described_class.weight_tier_label(1)).to eq("1–2499 lbs")
      expect(described_class.weight_tier_label(2_499)).to eq("1–2499 lbs")
      expect(described_class.weight_tier_label(2_500)).to eq("2500–3499 lbs")
      expect(described_class.weight_tier_label(3_499)).to eq("2500–3499 lbs")
      expect(described_class.weight_tier_label(3_500)).to eq("3500–4999 lbs")
      expect(described_class.weight_tier_label(4_999)).to eq("3500–4999 lbs")
      expect(described_class.weight_tier_label(5_000)).to eq("Over 4999 lbs")
    end

    it "reports a title fee of 7,775 cents" do
      expect(described_class.title_fee_cents).to eq(7_775)
    end

    it "reports ELT as available and lease liens as not required" do
      expect(described_class.elt_available?).to be(true)
      expect(described_class.lease_lien_required?).to be(false)
    end
  end

  describe "registration fees" do
    it "returns a registration line and a weight_fee line, in that order" do
      expect(described_class.fee_line_items(input).map(&:to_h)).to eq([
        { code: "registration", label: "Registration", amount_cents: 4_685 },
        { code: "weight_fee", label: "Weight fee", amount_cents: 5_670 }
      ])
    end

    # weight_lbs => [registration base, weight_fee (1.35 cents/lb, half-up), total]
    {
      0 => [2_760, 0, 2_760],
      1 => [2_760, 1, 2_761],
      2 => [2_760, 3, 2_763],
      10 => [2_760, 14, 2_774],
      30 => [2_760, 41, 2_801],
      2_490 => [2_760, 3_362, 6_122],
      2_499 => [2_760, 3_374, 6_134],
      2_500 => [4_035, 3_375, 7_410],
      3_499 => [4_035, 4_724, 8_759],
      3_500 => [4_685, 4_725, 9_410],
      4_200 => [4_685, 5_670, 10_355],
      4_999 => [4_685, 6_749, 11_434],
      5_000 => [7_240, 6_750, 13_990],
      20_000 => [7_240, 27_000, 34_240]
    }.each do |weight, (base, weight_fee, total)|
      it "charges #{base} + #{weight_fee} = #{total} cents at #{weight} lbs" do
        quote = input(weight_lbs: weight)

        expect(described_class.fee_line_items(quote).map(&:amount_cents)).to eq([base, weight_fee])
        expect(described_class.registration_fee_cents(quote)).to eq(total)
        expect(described_class.total_cents(quote)).to eq(total)
      end
    end

    it "rounds the weight fee half-up at exact half cents" do
      # 10 lbs * 1.35 = 13.5, 2,490 lbs * 1.35 = 3,361.5
      expect(described_class.fee_line_items(input(weight_lbs: 10)).last.amount_cents).to eq(14)
      expect(described_class.fee_line_items(input(weight_lbs: 2_490)).last.amount_cents).to eq(3_362)
    end

    it "produces a negative weight fee for negative weights" do
      quote = input(weight_lbs: -100)

      expect(described_class.fee_line_items(quote).map(&:amount_cents)).to eq([2_760, -135])
      expect(described_class.total_cents(quote)).to eq(2_625)
    end

    it "truncates fractional weights through QuoteInput integer casting" do
      expect(input(weight_lbs: 2_499.7).weight_lbs).to eq(2_499)
      expect(input(weight_lbs: "2499.7").weight_lbs).to eq(2_499)
      expect(described_class.total_cents(input(weight_lbs: "2499.7"))).to eq(6_134)
    end

    it "raises NoMethodError when weight_lbs is nil" do
      expect { described_class.fee_line_items(input(weight_lbs: nil)) }.to raise_error(NoMethodError)
    end

    it "ignores purchase price at every threshold" do
      [nil, 0, 1, 4_899_000, 1_000_000_000].each do |price|
        quote = input(purchase_price_cents: price)
        expect(described_class.fee_line_items(quote).map(&:amount_cents)).to eq([4_685, 5_670])
        expect(described_class.total_cents(quote)).to eq(10_355)
      end
    end

    it "ignores powertrain, usage, county, financing, lienholder ELT and buyer jurisdiction" do
      variants = [
        { powertrain: "bev" }, { powertrain: "phev" }, { powertrain: "ice" }, { powertrain: nil },
        { usage: "personal" }, { usage: "commercial" },
        { county: "miami-dade" }, { county: nil },
        { financing: "cash" }, { financing: "loan" }, { financing: "lease" }, { financing: "refinance" },
        { lienholder_elt: false },
        { buyer_jurisdiction: "GA" }
      ]

      variants.each do |attributes|
        quote = input(**attributes)
        expect(described_class.fee_line_items(quote).map(&:to_h)).to eq([
          { code: "registration", label: "Registration", amount_cents: 4_685 },
          { code: "weight_fee", label: "Weight fee", amount_cents: 5_670 }
        ])
      end
    end
  end

  describe "EV surcharge" do
    it "is zero for every powertrain because no ev_surcharge line item is produced" do
      %w[bev phev ice].each do |powertrain|
        quote = input(powertrain: powertrain)
        expect(described_class.ev_surcharge_cents(quote)).to eq(0)
        expect(described_class.fee_line_items(quote).map(&:code)).not_to include("ev_surcharge")
      end
    end

    it "keeps total_cents equal to registration_fee_cents" do
      [0, 2_499, 2_500, 3_499, 3_500, 4_999, 5_000].each do |weight|
        quote = input(weight_lbs: weight)
        expect(described_class.total_cents(quote)).to eq(described_class.registration_fee_cents(quote))
      end
    end
  end

  describe "temporary tags" do
    it "is valid for 30 days regardless of usage, buyer, financing, powertrain or weight" do
      [
        {}, { usage: "commercial" }, { buyer_jurisdiction: "GA" }, { financing: "loan" },
        { powertrain: "ice" }, { weight_lbs: 5_000 }, { delivery_date: nil }
      ].each do |attributes|
        expect(described_class.temp_tag_valid_days(input(**attributes))).to eq(30)
      end
    end

    it "expires 29 days after delivery, so the delivery day counts as day 1 of 30" do
      quote = input(delivery_date: Date.new(2025, 6, 10))

      expect(described_class.temp_tag_expires_on(quote)).to eq(Date.new(2025, 7, 9))
      expect((described_class.temp_tag_expires_on(quote) - quote.delivery_date).to_i).to eq(29)
      expect(described_class.temp_tag_expires_on(quote)).to eq(
        quote.delivery_date + described_class.temp_tag_valid_days(quote) - 1
      )
    end

    {
      Date.new(2025, 1, 1) => Date.new(2025, 1, 30),
      Date.new(2025, 1, 2) => Date.new(2025, 1, 31),
      Date.new(2025, 1, 3) => Date.new(2025, 2, 1),
      Date.new(2025, 1, 31) => Date.new(2025, 3, 1),
      Date.new(2025, 2, 1) => Date.new(2025, 3, 2),
      Date.new(2025, 2, 28) => Date.new(2025, 3, 29),
      Date.new(2024, 1, 31) => Date.new(2024, 2, 29),
      Date.new(2024, 2, 1) => Date.new(2024, 3, 1),
      Date.new(2024, 2, 29) => Date.new(2024, 3, 29),
      Date.new(2025, 12, 3) => Date.new(2026, 1, 1),
      Date.new(2025, 12, 31) => Date.new(2026, 1, 29)
    }.each do |delivery, expiry|
      it "expires on #{expiry.iso8601} for delivery on #{delivery.iso8601}" do
        expect(described_class.temp_tag_expires_on(input(delivery_date: delivery))).to eq(expiry)
      end
    end

    it "does not change the expiry for commercial use or an out-of-state buyer" do
      expect(described_class.temp_tag_expires_on(input(usage: "commercial"))).to eq(Date.new(2025, 7, 9))
      expect(described_class.temp_tag_expires_on(input(buyer_jurisdiction: "GA"))).to eq(Date.new(2025, 7, 9))
    end

    it "casts ISO date strings and leaves invalid dates nil" do
      expect(described_class.temp_tag_expires_on(input(delivery_date: "2025-06-10"))).to eq(Date.new(2025, 7, 9))
      expect(input(delivery_date: "2025-02-30").delivery_date).to be_nil
    end

    it "raises NoMethodError when delivery_date is nil" do
      expect { described_class.temp_tag_expires_on(input(delivery_date: nil)) }.to raise_error(NoMethodError)
    end
  end

  describe "lien filing determination" do
    def lien(**attributes)
      quote = input(**attributes)
      [
        described_class.lien_filing_required?(quote),
        described_class.lien_filing_method(quote),
        described_class.lien_reason(quote)
      ]
    end

    electronic = [true, "electronic", "Electronic filing via Florida ELT"]
    paper = [true, "paper", "Paper filing with Florida motor vehicle agency"]
    none = [false, nil, "No lien to record"]

    context "with an in-state buyer and an ELT lienholder" do
      it "files electronically for loan and refinance" do
        expect(lien(financing: "loan")).to eq(electronic)
        expect(lien(financing: "refinance")).to eq(electronic)
      end

      it "records no lien for cash and lease" do
        expect(lien(financing: "cash")).to eq(none)
        expect(lien(financing: "lease")).to eq(none)
      end

      it "defaults financing to cash and records no lien" do
        quote = Jurisdictions::QuoteInput.new(jurisdiction: "FL")
        expect(quote.financing).to eq("cash")
        expect(described_class.lien_filing_required?(quote)).to be(false)
      end

      it "treats nil, unknown and differently cased financing values as not financed" do
        [nil, "", "LOAN", "Loan", " loan", "Refinance", "credit"].each do |financing|
          expect(lien(financing: financing)).to eq(none)
        end
      end
    end

    context "with an in-state buyer and a non-ELT lienholder" do
      it "files on paper for loan and refinance" do
        expect(lien(financing: "loan", lienholder_elt: false)).to eq(paper)
        expect(lien(financing: "refinance", lienholder_elt: false)).to eq(paper)
      end

      it "records no lien for cash and lease" do
        expect(lien(financing: "cash", lienholder_elt: false)).to eq(none)
        expect(lien(financing: "lease", lienholder_elt: false)).to eq(none)
      end
    end

    context "with lienholder_elt casting" do
      it "defaults lienholder_elt to true" do
        expect(Jurisdictions::QuoteInput.new.lienholder_elt).to be(true)
        expect(lien(financing: "loan")).to eq(electronic)
      end

      it "files on paper when lienholder_elt casts to false or nil" do
        [false, nil, "", "false", "0", "f", "off", 0].each do |value|
          expect(lien(financing: "loan", lienholder_elt: value)).to eq(paper)
        end
      end

      it "files electronically when lienholder_elt casts to true, including the string \"no\"" do
        [true, "true", "1", "t", "yes", "no", 1].each do |value|
          expect(lien(financing: "loan", lienholder_elt: value)).to eq(electronic)
        end
      end
    end

    context "with an out-of-state buyer" do
      it "records no lien for every financing type and ELT setting" do
        %w[cash loan lease refinance].each do |financing|
          [true, false].each do |elt|
            expect(lien(financing: financing, lienholder_elt: elt, buyer_jurisdiction: "GA")).to eq(none)
          end
        end
      end

      it "treats any buyer jurisdiction string that differs from FL as out of state" do
        expect(lien(financing: "loan", buyer_jurisdiction: "CA")).to eq(none)
        expect(lien(financing: "loan", buyer_jurisdiction: "ZZ")).to eq(none)
      end

      it "normalizes buyer_jurisdiction case and whitespace before comparing" do
        expect(lien(financing: "loan", buyer_jurisdiction: " fl ")).to eq(electronic)
        expect(lien(financing: "loan", buyer_jurisdiction: "ga")).to eq(none)
      end

      it "falls back to the quote jurisdiction when buyer_jurisdiction is nil or blank" do
        expect(input(buyer_jurisdiction: nil).buyer_jurisdiction).to eq("FL")
        expect(input(buyer_jurisdiction: "  ").buyer_jurisdiction).to eq("FL")
        expect(lien(financing: "loan", buyer_jurisdiction: nil)).to eq(electronic)
        expect(lien(financing: "loan", buyer_jurisdiction: "")).to eq(electronic)
      end
    end

    context "with the input jurisdiction" do
      it "compares the buyer against input.jurisdiction, not against FL" do
        quote = input(jurisdiction: "GA", buyer_jurisdiction: "GA", financing: "loan")
        expect(described_class.lien_filing_required?(quote)).to be(true)

        quote = input(jurisdiction: "GA", buyer_jurisdiction: "FL", financing: "loan")
        expect(described_class.lien_filing_required?(quote)).to be(false)
      end

      it "is in state when both jurisdiction and buyer are nil" do
        quote = input(jurisdiction: nil, buyer_jurisdiction: nil, financing: "loan")
        expect(quote.out_of_state_buyer?).to be(false)
        expect(described_class.lien_filing_required?(quote)).to be(true)
      end
    end

    it "does not depend on weight, price, delivery date, powertrain, usage or county" do
      quote = Jurisdictions::QuoteInput.new(jurisdiction: "FL", financing: "loan", lienholder_elt: true)
      expect(described_class.lien_filing_required?(quote)).to be(true)
      expect(described_class.lien_filing_method(quote)).to eq("electronic")
    end

    it "records no lien for lease with or without an ELT lienholder" do
      expect(described_class.lease_lien_required?).to be(false)
      expect(lien(financing: "lease", lienholder_elt: true)).to eq(none)
      expect(lien(financing: "lease", lienholder_elt: false)).to eq(none)
    end
  end
end
