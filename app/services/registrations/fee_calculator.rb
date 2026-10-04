module Registrations
  class FeeCalculator
    Result = Struct.new(:jurisdiction, :input, :line_items, :registration_fee_cents, :ev_surcharge_cents, :total_cents, keyword_init: true)

    def self.call(vehicle:, delivery_date: vehicle.delivery_date)
      jurisdiction = Jurisdictions.for(vehicle.jurisdiction_code)
      input = Jurisdictions::QuoteInput.new(
        jurisdiction: vehicle.jurisdiction_code,
        weight_lbs: vehicle.weight_lbs,
        purchase_price_cents: vehicle.purchase_price_cents,
        powertrain: vehicle.powertrain,
        financing: vehicle.financing,
        lienholder_elt: vehicle.lienholder_elt,
        buyer_jurisdiction: vehicle.customer.jurisdiction_code,
        county: vehicle.county,
        usage: vehicle.usage,
        delivery_date: delivery_date
      )
      items = jurisdiction.fee_line_items(input)
      Result.new(
        jurisdiction: jurisdiction,
        input: input,
        line_items: items,
        registration_fee_cents: items.reject { |item| item.code == "ev_surcharge" }.sum(&:amount_cents),
        ev_surcharge_cents: items.find { |item| item.code == "ev_surcharge" }&.amount_cents.to_i,
        total_cents: items.sum(&:amount_cents)
      )
    end
  end
end
