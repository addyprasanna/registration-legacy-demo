module Jurisdictions
  class Wisconsin < StandardRules
    NAME = "Wisconsin"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3833, 15400], [7591, 17900], [nil, 20400]].freeze
    PRICE_RATE = nil
    EV_SURCHARGE_CENTS = 20700
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 83
    ELT = true
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 3300
  end
end
