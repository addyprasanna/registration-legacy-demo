module Jurisdictions
  class Delaware < StandardRules
    NAME = "Delaware"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[2686, 4300], [6222, 6800], [nil, 9300]].freeze
    PRICE_RATE = BigDecimal("0.007")
    EV_SURCHARGE_CENTS = 0
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 20
    ELT = false
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 3600
  end
end
