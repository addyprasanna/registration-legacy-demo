module Jurisdictions
  class Texas < Base
    NAME = "Texas"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 1
    WEIGHT_TIERS = [[4_000, 5_075], [6_000, 6_250], [nil, 7_825]].freeze
    TEMP_TAG_DAYS = 60
    ELT = true
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 3_300
    EV_SURCHARGE_CENTS = 20_000

    def self.fee_line_items(input)
      weight = input.weight_lbs
      amount = if weight <= 4_000
                 5_075
               elsif weight < 6_000
                 6_250
               else
                 7_825
               end
      items = [LineItem.new(code: "registration", label: weight <= 4_000 ? "Up to 4,000 lbs" : (weight < 6_000 ? "4,001–6,000 lbs" : "Over 6,000 lbs"), amount_cents: amount)]
      county_fee = { "TRAVIS" => 1_000, "HARRIS" => 1_100, "DALLAS" => 1_150, "BEXAR" => 950 }.fetch(input.county, 0)
      items << money_item("county_fee", "County fee", county_fee)
      ev = { "bev" => 20_000, "phev" => 7_500 }.fetch(input.powertrain, 0)
      items << money_item("ev_surcharge", "EV surcharge", ev)
      items.compact
    end

    def self.temp_tag_valid_days(input)
      input.out_of_state_buyer? ? 30 : 60
    end
  end
end
