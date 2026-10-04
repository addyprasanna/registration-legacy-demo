require "ostruct"

module Jurisdictions
  class Ontario < Base
    include OntarioRules

    NAME = "Ontario"
    COUNTRY = "CA"
    CURRENCY = "CAD"
    TIER = 1
    WEIGHT_TIERS = [[3_299, 5_900], [5_499, 9_000], [nil, 12_000]].freeze
    TEMP_TAG_DAYS = 40
    EV_SURCHARGE_CENTS = 5_000
    ELT = true
    LEASE_LIEN_REQUIRED = true
    TITLE_FEE_CENTS = 3_200

    def self.fee_line_items(input)
      wrapper = OpenStruct.new(vehicle_weight_lbs: input.weight_lbs, price_cents: input.price_cents, delivery_date: input.delivery_date)
      wrapper.extend(OntarioRules)
      amount = wrapper.ontario_registration_fee_cents - wrapper.ontario_rst_component_cents
      rst = wrapper.ontario_rst_component_cents
      ev = { "bev" => 5_000, "phev" => 2_500 }.fetch(input.powertrain, 0)
      [LineItem.new(code: "registration", label: "Registration", amount_cents: amount),
       money_item("rst", "Retail sales tax", rst),
       money_item("ev_surcharge", "EV surcharge", ev)].compact
    end

    def self.total_cents(input)
      fee_line_items(input).sum(&:amount_cents)
    end

    def self.temp_tag_valid_days(input)
      input.usage == "commercial" ? 10 : 40
    end

    def self.lien_filing_method(input)
      lien_filing_required?(input) ? "electronic" : nil
    end

    def self.weight_tier_label(weight)
      super
    end
  end
end
