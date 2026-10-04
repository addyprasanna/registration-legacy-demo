module Titling
  class StatusTracker
    FLOW = %w[draft submitted in_review issued].freeze

    def initialize(application)
      @application = application
    end

    def advance!(at: Time.current)
      current = FLOW.index(@application.status)
      next_status = current && FLOW[current + 1]
      return @application unless next_status

      @application.status = next_status
      @application.submitted_at = at if next_status == "submitted"
      @application.issued_at = at if next_status == "issued"
      @application.title_number = "TL-#{@application.jurisdiction_code}-#{@application.id.to_s.rjust(6, '0')}" if next_status == "issued"
      @application.status_history = Array(@application.status_history) + [{ "status" => next_status, "at" => at.iso8601 }]
      @application.save!
      @application
    end
  end
end
