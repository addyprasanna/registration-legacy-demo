module Jurisdictions
  class Quebec < StandardRules
    NAME = "Quebec"
    COUNTRY = "CA"
    CURRENCY = "CAD"
    TIER = 2
    WEIGHT_TIERS = [[3957, 16600], [7739, 19100], [nil, 21600]].freeze
    PRICE_RATE = nil
    EV_SURCHARGE_CENTS = 5800
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 90
    ELT = true
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 3700
  end
end
