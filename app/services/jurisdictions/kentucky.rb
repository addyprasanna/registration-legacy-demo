module Jurisdictions
  class Kentucky < StandardRules
    NAME = "Kentucky"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[2934, 6700], [6518, 9200], [nil, 11700]].freeze
    PRICE_RATE = BigDecimal("0.015")
    EV_SURCHARGE_CENTS = 23200
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 33
    ELT = true
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 4400
  end
end
