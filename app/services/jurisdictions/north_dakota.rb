module Jurisdictions
  class NorthDakota < StandardRules
    NAME = "North Dakota"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3430, 11500], [7110, 14000], [nil, 16500]].freeze
    PRICE_RATE = BigDecimal("0.001")
    EV_SURCHARGE_CENTS = 0
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 61
    ELT = false
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 4000
  end
end
