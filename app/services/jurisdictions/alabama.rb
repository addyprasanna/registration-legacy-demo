module Jurisdictions
  class Alabama < StandardRules
    NAME = "Alabama"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[2500, 2500], [6000, 5000], [nil, 7500]].freeze
    PRICE_RATE = BigDecimal("0.001")
    EV_SURCHARGE_CENTS = 0
    PHEV_SURCHARGE_CENTS = 2500
    TEMP_TAG_DAYS = 10
    ELT = false
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 3000
  end
end
