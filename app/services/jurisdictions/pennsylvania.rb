module Jurisdictions
  class Pennsylvania < StandardRules
    NAME = "Pennsylvania"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3554, 12700], [7258, 15200], [nil, 17700]].freeze
    PRICE_RATE = BigDecimal("0.005")
    EV_SURCHARGE_CENTS = 9000
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 67
    ELT = true
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 4400
  end
end
