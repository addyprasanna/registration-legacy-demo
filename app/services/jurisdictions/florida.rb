module Jurisdictions
  class Florida < Base
    NAME = "Florida"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 1
    WEIGHT_TIERS = [[2_499, 2_760], [3_499, 4_035], [4_999, 4_685], [nil, 7_240]].freeze
    TEMP_TAG_DAYS = 30
    ELT = true
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 7_775
    EV_SURCHARGE_CENTS = 0

    def self.fee_line_items(input)
      base = WEIGHT_TIERS.find { |max, _| max.nil? || input.weight_lbs <= max }.last
      weight_fee = round_cents(BigDecimal(input.weight_lbs.to_s) * 135 / 100)
      [LineItem.new(code: "registration", label: "Registration", amount_cents: base),
       LineItem.new(code: "weight_fee", label: "Weight fee", amount_cents: weight_fee)]
    end

    def self.temp_tag_expires_on(input)
      input.delivery_date + temp_tag_valid_days(input) - 1
    end

    def self.lien_filing_required?(input)
      return false if input.out_of_state_buyer?

      input.financed?
    end
  end
end
