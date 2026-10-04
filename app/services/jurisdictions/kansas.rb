module Jurisdictions
  class Kansas < StandardRules
    NAME = "Kansas"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[2903, 6400], [6481, 8900], [nil, 11400]].freeze
    PRICE_RATE = nil
    EV_SURCHARGE_CENTS = 21900
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 32
    ELT = true
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 4300
  end
end
