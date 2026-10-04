module Jurisdictions
  class Alaska < StandardRules
    NAME = "Alaska"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[2531, 2800], [6037, 5300], [nil, 7800]].freeze
    PRICE_RATE = nil
    EV_SURCHARGE_CENTS = 6300
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 11
    ELT = true
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 3100
  end
end
