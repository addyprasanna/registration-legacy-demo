module Api
  module V1
    class TempTagsController < BaseController
      include TexasInTransitOverride

      def create
        body = raw_body
        return validation_error("body", "must be a JSON object") unless body.is_a?(Hash)
        valid, vin = validate_string(optional_value(body, "vin"), "vin", required: true)
        return if performed? || !valid
        valid, issue_date = validate_date(optional_value(body, "issue_date"), "issue_date", required: true)
        return if performed? || !valid
        valid, usage = validate_string(optional_value(body, "usage"), "usage", required: false, allowed: %w[personal commercial])
        return if performed? || !valid
        valid, buyer = validate_jurisdiction(optional_value(body, "buyer_jurisdiction"), field: "buyer_jurisdiction", required: false)
        return if performed? || !valid
        vehicle = CustomerAccounts::Vehicle.includes(:customer).find_by(vin: vin)
        return render_error(:not_found, "Vehicle not found", [], :not_found) unless vehicle

        target_buyer = buyer || vehicle.jurisdiction_code
        input = Jurisdictions::QuoteInput.new(
          jurisdiction: vehicle.jurisdiction_code,
          weight_lbs: vehicle.weight_lbs,
          purchase_price_cents: vehicle.purchase_price_cents,
          buyer_jurisdiction: target_buyer,
          usage: usage || vehicle.usage,
          delivery_date: issue_date
        )
        days = temp_tag_days_for(Jurisdictions.for(vehicle.jurisdiction_code), input)
        tag = TempTags::IssueService.call(
          vehicle: vehicle,
          issue_date: issue_date,
          buyer_jurisdiction: target_buyer,
          usage: usage || vehicle.usage,
          valid_days: days
        )
        render_data(tag_payload(tag), status: :created)
      end

      def show
        tag = TempTags::TempTag.find_by!(tag_number: params[:tag_number])
        render_data(tag_payload(tag))
      end

      private

      def tag_payload(tag)
        {
          tag_number: tag.tag_number,
          vin: tag.vehicle.vin,
          jurisdiction: tag.jurisdiction_code,
          issued_on: tag.issued_on.iso8601,
          valid_days: tag.valid_days,
          expires_on: tag.expires_on.iso8601,
          status: tag.status
        }
      end
    end
  end
end
