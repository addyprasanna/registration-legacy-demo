module Jurisdictions
  class Arizona < StandardRules
    NAME = "Arizona"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[2562, 3100], [6074, 5600], [nil, 8100]].freeze
    PRICE_RATE = BigDecimal("0.003")
    EV_SURCHARGE_CENTS = 7600
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 13
    ELT = true
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 3200
  end
end
