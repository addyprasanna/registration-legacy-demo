module Jurisdictions
  class WestVirginia < StandardRules
    NAME = "West Virginia"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3802, 15100], [7554, 17600], [nil, 20100]].freeze
    PRICE_RATE = BigDecimal("0.013")
    EV_SURCHARGE_CENTS = 0
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 81
    ELT = false
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 3200
  end
end
