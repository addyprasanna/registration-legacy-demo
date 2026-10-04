module Jurisdictions
  class StandardRules < Base
    def self.fee_line_items(input)
      max, base = const_get(:WEIGHT_TIERS).find { |upper, _| upper.nil? || input.weight_lbs <= upper }
      items = [LineItem.new(code: "registration", label: "Registration", amount_cents: base)]
      if const_defined?(:PRICE_RATE) && const_get(:PRICE_RATE)
        amount = round_cents(BigDecimal(input.price_cents.to_s) * const_get(:PRICE_RATE))
        items << money_item("ad_valorem", "Value-based tax", amount)
      end
      surcharge = case input.powertrain
                  when "bev"
                    const_get(:EV_SURCHARGE_CENTS)
                  when "phev"
                    const_defined?(:PHEV_SURCHARGE_CENTS) ? const_get(:PHEV_SURCHARGE_CENTS) : 0
                  else
                    0
                  end
      items << money_item("ev_surcharge", "EV surcharge", surcharge)
      items.compact
    end
  end
end
