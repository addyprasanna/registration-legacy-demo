module Jurisdictions
  class Minnesota < StandardRules
    NAME = "Minnesota"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3120, 8500], [6740, 11000], [nil, 13500]].freeze
    PRICE_RATE = BigDecimal("0.006")
    EV_SURCHARGE_CENTS = 10900
    PHEV_SURCHARGE_CENTS = 2500
    TEMP_TAG_DAYS = 44
    ELT = true
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 3000
  end
end
