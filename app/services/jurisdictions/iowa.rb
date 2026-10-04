module Jurisdictions
  class Iowa < StandardRules
    NAME = "Iowa"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[2872, 6100], [6444, 8600], [nil, 11100]].freeze
    PRICE_RATE = BigDecimal("0.013")
    EV_SURCHARGE_CENTS = 0
    PHEV_SURCHARGE_CENTS = 2500
    TEMP_TAG_DAYS = 30
    ELT = false
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 4200
  end
end
