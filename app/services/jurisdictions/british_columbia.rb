module Jurisdictions
  class BritishColumbia < StandardRules
    NAME = "British Columbia"
    COUNTRY = "CA"
    CURRENCY = "CAD"
    TIER = 2
    WEIGHT_TIERS = [[3926, 16300], [7702, 18800], [nil, 21300]].freeze
    PRICE_RATE = BigDecimal("0.002")
    EV_SURCHARGE_CENTS = 24600
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 88
    ELT = true
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 3600
  end
end
