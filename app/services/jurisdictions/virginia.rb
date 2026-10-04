module Jurisdictions
  class Virginia < StandardRules
    NAME = "Virginia"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3771, 14800], [7517, 17300], [nil, 19800]].freeze
    PRICE_RATE = nil
    EV_SURCHARGE_CENTS = 18100
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 79
    ELT = true
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 3100
  end
end
