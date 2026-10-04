module Api
  module V1
    class RegistrationQuotesController < BaseController
      def create
        body = raw_body
        return validation_error("body", "must be a JSON object") unless body.is_a?(Hash)
        return validation_error("jurisdiction", "is required") unless body["jurisdiction"].is_a?(String)
        jurisdiction = body["jurisdiction"].strip.upcase
        return unknown_jurisdiction(jurisdiction) unless Jurisdictions.codes.include?(jurisdiction)

        valid, weight = validate_integer(optional_value(body, "weight_lbs"), "weight_lbs", required: true, min: 1, max: 20_000)
        return if performed? || !valid
        valid, price = validate_integer(optional_value(body, "purchase_price_cents"), "purchase_price_cents", required: true, min: 0, max: 1_000_000_000)
        return if performed? || !valid
        valid, date = validate_date(optional_value(body, "delivery_date"), "delivery_date", required: true)
        return if performed? || !valid
        valid, powertrain = validate_string(optional_value(body, "powertrain"), "powertrain", required: false, allowed: %w[bev phev ice])
        return if performed? || !valid
        valid, financing = validate_string(optional_value(body, "financing"), "financing", required: false, allowed: %w[cash loan lease refinance])
        return if performed? || !valid
        valid, usage = validate_string(optional_value(body, "usage"), "usage", required: false, allowed: %w[personal commercial])
        return if performed? || !valid
        valid, county = validate_string(optional_value(body, "county"), "county", required: false, max_length: 64)
        return if performed? || !valid
        valid, lienholder_elt = validate_boolean(optional_value(body, "lienholder_elt"), "lienholder_elt", default: true)
        return if performed? || !valid
        valid, buyer = validate_jurisdiction(optional_value(body, "buyer_jurisdiction"), field: "buyer_jurisdiction", required: false, default: jurisdiction)
        return if performed? || !valid

        input = Jurisdictions::QuoteInput.new(
          jurisdiction: jurisdiction,
          weight_lbs: weight,
          purchase_price_cents: price,
          delivery_date: date,
          powertrain: powertrain || "bev",
          financing: financing || "cash",
          usage: usage || "personal",
          county: county,
          lienholder_elt: lienholder_elt,
          buyer_jurisdiction: buyer
        )
        klass = Jurisdictions.for(jurisdiction)
        items = klass.fee_line_items(input)
        render_data(
          jurisdiction: jurisdiction,
          jurisdiction_name: klass.display_name,
          currency: klass.currency,
          line_items: items.map { |item| { code: item.code, label: item.label, amount_cents: item.amount_cents } },
          registration_fee_cents: items.reject { |item| item.code == "ev_surcharge" }.sum(&:amount_cents),
          ev_surcharge_cents: klass.ev_surcharge_cents(input),
          total_cents: items.sum(&:amount_cents),
          temp_tag: { valid_days: klass.temp_tag_valid_days(input), expires_on: klass.temp_tag_expires_on(input).iso8601 },
          lien: {
            required: klass.lien_filing_required?(input),
            filing_method: klass.lien_filing_method(input),
            reason: klass.lien_reason(input)
          }
        )
      end

      private

      def unknown_jurisdiction(code)
        message = "Unknown jurisdiction: #{code}"
        render_error(:unknown_jurisdiction, message, [{ field: "jurisdiction", message: message }], :unprocessable_entity)
      end
    end
  end
end
