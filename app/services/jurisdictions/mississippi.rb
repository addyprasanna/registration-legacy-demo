module Jurisdictions
  class Mississippi < StandardRules
    NAME = "Mississippi"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3151, 8800], [6777, 11300], [nil, 13800]].freeze
    PRICE_RATE = nil
    EV_SURCHARGE_CENTS = 0
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 45
    ELT = false
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 3100
  end
end
