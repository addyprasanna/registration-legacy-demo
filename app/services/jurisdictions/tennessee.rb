module Jurisdictions
  class Tennessee < StandardRules
    NAME = "Tennessee"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3678, 13900], [7406, 16400], [nil, 18900]].freeze
    PRICE_RATE = BigDecimal("0.009")
    EV_SURCHARGE_CENTS = 14200
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 74
    ELT = true
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 4800
  end
end
