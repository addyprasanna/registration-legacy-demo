module Jurisdictions
  class NewJersey < StandardRules
    NAME = "New Jersey"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3337, 10600], [6999, 13100], [nil, 15600]].freeze
    PRICE_RATE = nil
    EV_SURCHARGE_CENTS = 0
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 55
    ELT = false
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 3700
  end
end
