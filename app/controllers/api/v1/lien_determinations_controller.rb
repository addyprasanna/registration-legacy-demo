module Api
  module V1
    class LienDeterminationsController < BaseController
      def create
        body = raw_body
        return validation_error("body", "must be a JSON object") unless body.is_a?(Hash)
        valid, jurisdiction = validate_jurisdiction(optional_value(body, "jurisdiction"))
        return if performed? || !valid
        valid, financing = validate_string(optional_value(body, "financing"), "financing", required: true, allowed: %w[cash loan lease refinance])
        return if performed? || !valid
        valid, elt = validate_boolean(optional_value(body, "lienholder_elt"), "lienholder_elt", default: true)
        return if performed? || !valid
        valid, buyer = validate_jurisdiction(optional_value(body, "buyer_jurisdiction"), field: "buyer_jurisdiction", required: false, default: jurisdiction)
        return if performed? || !valid

        input = Jurisdictions::QuoteInput.new(
          jurisdiction: jurisdiction,
          financing: financing,
          lienholder_elt: elt,
          buyer_jurisdiction: buyer
        )
        result = LienFilings::DeterminationService.call(input)
        render_data(
          jurisdiction: jurisdiction,
          financing: financing,
          lien_filing_required: result.required,
          filing_method: result.filing_method,
          elt_available: result.jurisdiction.elt_available?,
          reason: result.reason
        )
      end
    end
  end
end
