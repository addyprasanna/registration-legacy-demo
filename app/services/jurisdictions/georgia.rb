module Jurisdictions
  class Georgia < StandardRules
    NAME = "Georgia"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[2717, 4600], [6259, 7100], [nil, 9600]].freeze
    PRICE_RATE = nil
    EV_SURCHARGE_CENTS = 14100
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 21
    ELT = true
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 3700
  end
end
