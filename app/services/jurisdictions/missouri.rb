module Jurisdictions
  class Missouri < StandardRules
    NAME = "Missouri"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3182, 9100], [6814, 11600], [nil, 14100]].freeze
    PRICE_RATE = BigDecimal("0.008")
    EV_SURCHARGE_CENTS = 13500
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 47
    ELT = true
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 3200
  end
end
