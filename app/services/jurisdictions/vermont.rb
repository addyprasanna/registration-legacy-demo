module Jurisdictions
  class Vermont < StandardRules
    NAME = "Vermont"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3740, 14500], [7480, 17000], [nil, 19500]].freeze
    PRICE_RATE = BigDecimal("0.011")
    EV_SURCHARGE_CENTS = 16800
    PHEV_SURCHARGE_CENTS = 2500
    TEMP_TAG_DAYS = 78
    ELT = true
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 3000
  end
end
