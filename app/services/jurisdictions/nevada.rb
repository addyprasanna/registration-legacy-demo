module Jurisdictions
  class Nevada < StandardRules
    NAME = "Nevada"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3275, 10000], [6925, 12500], [nil, 15000]].freeze
    PRICE_RATE = nil
    EV_SURCHARGE_CENTS = 17400
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 52
    ELT = true
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 3500
  end
end
