module Jurisdictions
  class Connecticut < StandardRules
    NAME = "Connecticut"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[2655, 4000], [6185, 6500], [nil, 9000]].freeze
    PRICE_RATE = nil
    EV_SURCHARGE_CENTS = 11500
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 18
    ELT = true
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 3500
  end
end
