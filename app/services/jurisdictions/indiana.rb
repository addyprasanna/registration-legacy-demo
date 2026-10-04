module Jurisdictions
  class Indiana < StandardRules
    NAME = "Indiana"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[2841, 5800], [6407, 8300], [nil, 10800]].freeze
    PRICE_RATE = nil
    EV_SURCHARGE_CENTS = 19300
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 28
    ELT = true
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 4100
  end
end
