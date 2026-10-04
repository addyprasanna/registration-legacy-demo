module Titling
  class StatusTracker
    class LienPending < StandardError; end

    FLOW = %w[draft submitted in_review issued].freeze

    def initialize(application)
      @application = application
    end

    def advance!(at: Time.current)
      current = FLOW.index(@application.status)
      next_status = current && FLOW[current + 1]
      return @application unless next_status
      if next_status == "issued" && @application.vehicle.lien_filings.where(status: "pending").exists?
        raise LienPending, "Title can't be issued while a lien filing is pending."
      end

      @application.status = next_status
      @application.submitted_at = at if next_status == "submitted"
      @application.issued_at = at if next_status == "issued"
      @application.title_number = "TL-#{@application.jurisdiction_code}-#{@application.id.to_s.rjust(6, '0')}" if next_status == "issued"
      @application.status_history = Array(@application.status_history) + [{ "status" => next_status, "at" => at.iso8601 }]
      ApplicationRecord.transaction do
        @application.save!
        ::StatusEvent.create!(
          vehicle: @application.vehicle,
          domain: "titling",
          subject_type: @application.class.name,
          subject_id: @application.id,
          event: "status_changed",
          from_status: @application.status_before_last_save,
          to_status: next_status,
          occurred_at: at
        )
      end
      @application
    end
  end
end
