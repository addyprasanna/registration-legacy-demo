module Jurisdictions
  class Nebraska < StandardRules
    NAME = "Nebraska"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3244, 9700], [6888, 12200], [nil, 14700]].freeze
    PRICE_RATE = BigDecimal("0.010")
    EV_SURCHARGE_CENTS = 0
    PHEV_SURCHARGE_CENTS = 2500
    TEMP_TAG_DAYS = 50
    ELT = false
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 3400
  end
end
