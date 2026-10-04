module Jurisdictions
  class DistrictOfColumbia < StandardRules
    NAME = "District of Columbia"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 2
    WEIGHT_TIERS = [[3895, 16000], [7665, 18500], [nil, 21000]].freeze
    PRICE_RATE = nil
    EV_SURCHARGE_CENTS = 0
    PHEV_SURCHARGE_CENTS = 0
    TEMP_TAG_DAYS = 86
    ELT = false
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 3500
  end
end
