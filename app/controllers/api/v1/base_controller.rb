module Api
  module V1
    class BaseController < ActionController::API
      MISSING = Object.new.freeze

      before_action :require_json_content_type, if: :post_request?

      rescue_from StandardError do |error|
        Rails.logger.error("#{error.class}: #{error.message}")
        render_error(:internal_error, "Internal server error", [], :internal_server_error)
      end

      rescue_from ActiveRecord::RecordNotFound do
        render_error(:not_found, "Resource not found", [], :not_found)
      end

      rescue_from Jurisdictions::UnknownJurisdiction do |error|
        render_error(:unknown_jurisdiction, error.message, [{ field: "jurisdiction", message: error.message }], :unprocessable_entity)
      end

      rescue_from ActionDispatch::Http::Parameters::ParseError do
        render_error(:malformed_json, "Malformed JSON request", [], :bad_request)
      end

      private

      def post_request?
        request.post?
      end

      def require_json_content_type
        return if controller_name == "errors"
        return if request.media_type == "application/json"

        render_error(:unsupported_media_type, "Content-Type must be application/json", [], :unsupported_media_type)
      end

      def render_error(code, message, details = [], status = :unprocessable_entity)
        render json: {
          error: {
            code: code.to_s,
            message: message,
            details: details
          },
          meta: { request_id: request.request_id }
        }, status: status
      end

      def render_data(data = nil, status: :ok, **attributes)
        data ||= attributes
        render json: { data: data, meta: { request_id: request.request_id } }, status: status
      end

      def validation_error(field, message)
        render_error(:validation_failed, "Validation failed", [{ field: field.to_s, message: message }], :unprocessable_entity)
      end

      def validate_integer(value, field, required:, min:, max:)
        if value.equal?(MISSING)
          return validation_error(field, "is required") if required
          return [true, nil]
        end
        return [false, validation_error(field, "must be an integer")] unless value.is_a?(Integer)
        return [false, validation_error(field, "must be between #{min} and #{max}")] unless value.between?(min, max)

        [true, value]
      end

      def validate_string(value, field, required:, allowed: nil, max_length: nil)
        if value.equal?(MISSING)
          return validation_error(field, "is required") if required
          return [true, nil]
        end
        return [false, validation_error(field, "must be a string")] unless value.is_a?(String)
        return [false, validation_error(field, "is invalid")] if allowed && !allowed.include?(value)
        return [false, validation_error(field, "must be at most #{max_length} characters")] if max_length && value.length > max_length

        [true, value]
      end

      def validate_boolean(value, field, default:)
        return [true, default] if value.equal?(MISSING)
        return [true, value] if value == true || value == false

        [false, validation_error(field, "must be true or false")]
      end

      def validate_date(value, field, required:)
        if value.equal?(MISSING)
          return validation_error(field, "is required") if required
          return [true, nil]
        end
        return [false, validation_error(field, "must be a date in YYYY-MM-DD format")] unless value.is_a?(String) && value.match?(/\A\d{4}-\d{2}-\d{2}\z/)

        begin
          [true, Date.iso8601(value)]
        rescue Date::Error
          [false, validation_error(field, "must be a valid date")]
        end
      end

      def validate_jurisdiction(value, field: "jurisdiction", required: true, default: nil)
        if value.equal?(MISSING)
          return validation_error(field, "is required") if required
          return [true, default]
        end

        return validation_error(field, "must be a jurisdiction code") unless value.is_a?(String)
        unless Jurisdictions.codes.include?(value.strip.upcase)
          message = "Unknown jurisdiction: #{value.strip.upcase}"
          return render_error(:unknown_jurisdiction, message, [{ field: "jurisdiction", message: "is not a supported jurisdiction" }], :unprocessable_entity)
        end
        [true, value.strip.upcase]
      end

      def raw_body
        request.request_parameters
      end

      def optional_value(body, key)
        body.key?(key) ? body[key] : MISSING
      end
    end
  end
end
