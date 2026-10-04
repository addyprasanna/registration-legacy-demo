module Jurisdictions
  class Maine < StandardRules
    NAME = "Maine"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[2996, 7300], [6592, 9800], [nil, 12300]].freeze
    PRICE_RATE = BigDecimal("0.002")
    EV_SURCHARGE_CENTS = 5700
    PHEV_SURCHARGE_CENTS = 2500
    TEMP_TAG_DAYS = 37
    ELT = true
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 4600
  end
end
