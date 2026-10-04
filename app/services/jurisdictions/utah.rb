module Jurisdictions
  class Utah < StandardRules
    NAME = "Utah"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3709, 14200], [7443, 16700], [nil, 19200]].freeze
    PRICE_RATE = nil
    EV_SURCHARGE_CENTS = 0
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 76
    ELT = false
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 4900
  end
end
