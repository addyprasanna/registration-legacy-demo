module Jurisdictions
  class Illinois < StandardRules
    NAME = "Illinois"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[2810, 5500], [6370, 8000], [nil, 10500]].freeze
    PRICE_RATE = BigDecimal("0.011")
    EV_SURCHARGE_CENTS = 18000
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 27
    ELT = true
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 4000
  end
end
