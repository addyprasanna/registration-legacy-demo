module Jurisdictions
  class NorthCarolina < StandardRules
    NAME = "North Carolina"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3399, 11200], [7073, 13700], [nil, 16200]].freeze
    PRICE_RATE = nil
    EV_SURCHARGE_CENTS = 22600
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 59
    ELT = true
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 3900
  end
end
