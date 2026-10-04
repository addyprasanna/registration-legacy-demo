module Jurisdictions
  class Arkansas < StandardRules
    NAME = "Arkansas"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[2593, 3400], [6111, 5900], [nil, 8400]].freeze
    PRICE_RATE = nil
    EV_SURCHARGE_CENTS = 0
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 15
    ELT = false
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 3300
  end
end
