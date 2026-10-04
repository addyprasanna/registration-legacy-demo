module Jurisdictions
  class RhodeIsland < StandardRules
    NAME = "Rhode Island"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3585, 13000], [7295, 15500], [nil, 18000]].freeze
    PRICE_RATE = nil
    EV_SURCHARGE_CENTS = 10300
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 69
    ELT = true
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 4500
  end
end
