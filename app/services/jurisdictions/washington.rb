module Jurisdictions
  class Washington < Base
    NAME = "Washington"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 1
    WEIGHT_TIERS = [[3_999, 4_500], [4_999, 5_850], [6_499, 7_300], [nil, 9_600]].freeze
    TEMP_TAG_DAYS = 45
    ELT = true
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 3_500
    EV_SURCHARGE_CENTS = 15_000
    RTA_RATE = BigDecimal("0.011")

    def self.fee_line_items(input)
      base = WEIGHT_TIERS.find { |max, _| max.nil? || input.weight_lbs <= max }.last
      county_fee = CustomerAccounts::Vehicle::WA_RTA_COUNTIES.include?(input.county) ? round_cents(BigDecimal(input.price_cents.to_s) * RTA_RATE) : 0
      ev = { "bev" => 15_000, "phev" => 7_500 }.fetch(input.powertrain, 0)
      [LineItem.new(code: "registration", label: "Registration", amount_cents: base),
       money_item("rta_tax", "Regional transit tax", county_fee),
       money_item("ev_surcharge", "EV surcharge", ev)].compact
    end

    def self.temp_tag_valid_days(input)
      input.usage == "commercial" ? 20 : 45
    end
  end
end
