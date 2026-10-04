module Jurisdictions
  class NewHampshire < StandardRules
    NAME = "New Hampshire"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3306, 10300], [6962, 12800], [nil, 15300]].freeze
    PRICE_RATE = BigDecimal("0.012")
    EV_SURCHARGE_CENTS = 18700
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 54
    ELT = true
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 3600
  end
end
