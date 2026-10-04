module Jurisdictions
  class Maryland < StandardRules
    NAME = "Maryland"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3027, 7600], [6629, 10100], [nil, 12600]].freeze
    PRICE_RATE = nil
    EV_SURCHARGE_CENTS = 7000
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 38
    ELT = true
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 4700
  end
end
