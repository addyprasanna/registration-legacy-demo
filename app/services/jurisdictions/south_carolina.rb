module Jurisdictions
  class SouthCarolina < StandardRules
    NAME = "South Carolina"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3616, 13300], [7332, 15800], [nil, 18300]].freeze
    PRICE_RATE = BigDecimal("0.007")
    EV_SURCHARGE_CENTS = 0
    PHEV_SURCHARGE_CENTS = 2500
    TEMP_TAG_DAYS = 71
    ELT = false
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 4600
  end
end
