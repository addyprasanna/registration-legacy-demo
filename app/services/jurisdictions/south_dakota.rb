module Jurisdictions
  class SouthDakota < StandardRules
    NAME = "South Dakota"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3647, 13600], [7369, 16100], [nil, 18600]].freeze
    PRICE_RATE = nil
    EV_SURCHARGE_CENTS = 12900
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 72
    ELT = true
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 4700
  end
end
