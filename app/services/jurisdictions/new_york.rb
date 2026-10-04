module Jurisdictions
  class NewYork < Base
    NAME = "New York"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 1
    WEIGHT_TIERS = [[3_499, 3_250], [5_499, 5_180], [nil, 7_725]].freeze
    TEMP_TAG_DAYS = 30
    ELT = true
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 5_000
    EV_SURCHARGE_CENTS = 7_500
    AD_VALOREM_RATE = BigDecimal("0.0045")
    MCTD_COUNTIES = %w[NEW\ YORK KINGS QUEENS BRONX RICHMOND NASSAU SUFFOLK WESTCHESTER].freeze

    def self.fee_line_items(input)
      base = WEIGHT_TIERS.find { |max, _| max.nil? || input.weight_lbs <= max }.last
      ad_valorem = round_cents(BigDecimal(input.price_cents.to_s) * AD_VALOREM_RATE)
      county_fee = MCTD_COUNTIES.include?(input.county) ? 5_000 : 0
      ev = { "bev" => 7_500, "phev" => 3_750 }.fetch(input.powertrain, 0)
      [LineItem.new(code: "registration", label: "Registration", amount_cents: base),
       money_item("ad_valorem", "Value-based tax", ad_valorem),
       money_item("county_fee", "MCTD fee", county_fee),
       money_item("ev_surcharge", "EV surcharge", ev)].compact
    end

    def self.temp_tag_valid_days(input)
      input.out_of_state_buyer? ? 10 : 30
    end

    def self.lien_filing_method(input)
      return unless lien_filing_required?(input)
      return "paper" if input.refinance?

      super
    end
  end
end
