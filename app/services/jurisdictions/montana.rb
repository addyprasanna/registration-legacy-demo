module Jurisdictions
  class Montana < StandardRules
    NAME = "Montana"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3213, 9400], [6851, 11900], [nil, 14400]].freeze
    PRICE_RATE = nil
    EV_SURCHARGE_CENTS = 14800
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 49
    ELT = true
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 3300
  end
end
