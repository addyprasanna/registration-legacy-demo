module Jurisdictions
  class NewMexico < StandardRules
    NAME = "New Mexico"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3368, 10900], [7036, 13400], [nil, 15900]].freeze
    PRICE_RATE = BigDecimal("0.014")
    EV_SURCHARGE_CENTS = 21300
    PHEV_SURCHARGE_CENTS = 2500
    TEMP_TAG_DAYS = 57
    ELT = true
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 3800
  end
end
