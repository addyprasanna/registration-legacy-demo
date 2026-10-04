module Jurisdictions
  class Louisiana < StandardRules
    NAME = "Louisiana"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[2965, 7000], [6555, 9500], [nil, 12000]].freeze
    PRICE_RATE = nil
    EV_SURCHARGE_CENTS = 0
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 35
    ELT = false
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 4500
  end
end
