module Jurisdictions
  class Massachusetts < StandardRules
    NAME = "Massachusetts"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3058, 7900], [6666, 10400], [nil, 12900]].freeze
    PRICE_RATE = BigDecimal("0.004")
    EV_SURCHARGE_CENTS = 0
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 40
    ELT = false
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 4800
  end
end
