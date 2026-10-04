module Jurisdictions
  class Wyoming < StandardRules
    NAME = "Wyoming"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3864, 15700], [7628, 18200], [nil, 20700]].freeze
    PRICE_RATE = BigDecimal("0.015")
    EV_SURCHARGE_CENTS = 22000
    PHEV_SURCHARGE_CENTS = 2500
    TEMP_TAG_DAYS = 84
    ELT = true
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 3400
  end
end
