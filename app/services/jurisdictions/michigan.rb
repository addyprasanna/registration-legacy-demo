module Jurisdictions
  class Michigan < StandardRules
    NAME = "Michigan"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3089, 8200], [6703, 10700], [nil, 13200]].freeze
    PRICE_RATE = nil
    EV_SURCHARGE_CENTS = 9600
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 42
    ELT = true
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 4900
  end
end
