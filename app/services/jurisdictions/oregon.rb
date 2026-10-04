module Jurisdictions
  class Oregon < StandardRules
    NAME = "Oregon"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3523, 12400], [7221, 14900], [nil, 17400]].freeze
    PRICE_RATE = nil
    EV_SURCHARGE_CENTS = 0
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 66
    ELT = false
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 4300
  end
end
