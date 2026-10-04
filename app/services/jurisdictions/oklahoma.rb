module Jurisdictions
  class Oklahoma < StandardRules
    NAME = "Oklahoma"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3492, 12100], [7184, 14600], [nil, 17100]].freeze
    PRICE_RATE = BigDecimal("0.003")
    EV_SURCHARGE_CENTS = 6400
    PHEV_SURCHARGE_CENTS = 2500
    TEMP_TAG_DAYS = 64
    ELT = true
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 4200
  end
end
