module Jurisdictions
  class Hawaii < StandardRules
    NAME = "Hawaii"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[2748, 4900], [6296, 7400], [nil, 9900]].freeze
    PRICE_RATE = BigDecimal("0.009")
    EV_SURCHARGE_CENTS = 15400
    PHEV_SURCHARGE_CENTS = 2500
    TEMP_TAG_DAYS = 23
    ELT = true
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 3800
  end
end
