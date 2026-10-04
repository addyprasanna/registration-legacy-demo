module Jurisdictions
  class Ohio < StandardRules
    NAME = "Ohio"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3461, 11800], [7147, 14300], [nil, 16800]].freeze
    PRICE_RATE = nil
    EV_SURCHARGE_CENTS = 5100
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 62
    ELT = true
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 4100
  end
end
