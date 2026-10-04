module Jurisdictions
  class California < Base
    NAME = "California"
    COUNTRY = "US"
    CURRENCY = "USD"
    TIER = 1
    WEIGHT_TIERS = [[2_999, 6_500], [4_499, 8_500], [5_999, 11_000], [nil, 15_000]].freeze
    TEMP_TAG_DAYS = 90
    ELT = true
    LEASE_LIEN_REQUIRED = false
    TITLE_FEE_CENTS = 2_300
    EV_SURCHARGE_CENTS = 10_000

    def self.fee_line_items(input)
      weight = input.weight_lbs
      registration = WEIGHT_TIERS.find { |max, _| max.nil? || weight <= max }.last
      items = [LineItem.new(code: "registration", label: "Registration", amount_cents: registration)]
      ev = { "bev" => 10_000, "phev" => 5_000 }.fetch(input.powertrain, 0)
      items << money_item("ev_surcharge", "EV surcharge", ev)
      county_fee = { "LOS ANGELES" => 1_500, "SAN FRANCISCO" => 1_200, "ALAMEDA" => 900, "SAN DIEGO" => 1_000 }.fetch(input.county, 0)
      items << money_item("county_fee", "County fee", county_fee)
      items << money_item("commercial_plate", "Commercial plate", 2_500) if input.usage == "commercial"
      items.compact
    end

    def self.temp_tag_valid_days(input)
      input.usage == "commercial" ? 60 : 90
    end
  end
end
