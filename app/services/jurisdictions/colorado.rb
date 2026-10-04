module Jurisdictions
  class Colorado < StandardRules
    NAME = "Colorado"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[2624, 3700], [6148, 6200], [nil, 8700]].freeze
    PRICE_RATE = BigDecimal("0.005")
    EV_SURCHARGE_CENTS = 10200
    PHEV_SURCHARGE_CENTS = 2500
    TEMP_TAG_DAYS = 16
    ELT = true
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 3400
  end
end
