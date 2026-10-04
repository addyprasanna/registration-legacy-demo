module Jurisdictions
  class Idaho < StandardRules
    NAME = "Idaho"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[2779, 5200], [6333, 7700], [nil, 10200]].freeze
    PRICE_RATE = nil
    EV_SURCHARGE_CENTS = 0
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 25
    ELT = false
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 3900
  end
end
