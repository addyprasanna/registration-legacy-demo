module Registrations
  class Registration < ApplicationRecord
    self.table_name = "registrations"
    STATUSES = %w[draft submitted approved rejected].freeze

    belongs_to :vehicle, class_name: "CustomerAccounts::Vehicle"
    validates :status, inclusion: { in: STATUSES }
    before_save :stamp_ontario_currency
    after_commit :create_submission_records, on: :update, if: :submitted_status_changed?

    private

    def submitted_status_changed?
      status == "submitted" && saved_change_to_status?
    end

    def create_submission_records
      quote = FeeCalculator.call(vehicle: vehicle)
      input = quote.input
      at = submitted_at || Time.current
      create_pending_lien(quote.jurisdiction, input, at)
      create_draft_title(at)
    end

    def create_pending_lien(jurisdiction, input, at)
      return unless jurisdiction.lien_filing_required?(input)
      return if vehicle.lien_filings.where(status: %w[pending filed]).exists?

      filing = LienFilings::LienFiling.create!(
        vehicle: vehicle,
        jurisdiction_code: jurisdiction.code,
        financing: vehicle.financing,
        lienholder_name: vehicle.lienholder_name,
        elt_participant: vehicle.lienholder_elt,
        required: true,
        filing_method: jurisdiction.lien_filing_method(input),
        reason: jurisdiction.lien_reason(input),
        status: "pending"
      )
      ::StatusEvent.create!(
        vehicle: vehicle,
        domain: "lien_filings",
        subject_type: filing.class.name,
        subject_id: filing.id,
        event: "created",
        to_status: filing.status,
        occurred_at: at
      )
    end

    def create_draft_title(at)
      return if vehicle.title_applications.where.not(status: "rejected").exists?

      application = Titling::TitleApplication.create!(
        vehicle: vehicle,
        jurisdiction_code: jurisdiction_code,
        application_number: "TA-#{jurisdiction_code}-#{format('%06d', Titling::TitleApplication.count + 1)}",
        status: "draft",
        status_history: [{ "status" => "draft", "at" => at.iso8601 }]
      )
      ::StatusEvent.create!(
        vehicle: vehicle,
        domain: "titling",
        subject_type: application.class.name,
        subject_id: application.id,
        event: "created",
        to_status: application.status,
        occurred_at: at
      )
    end

    def stamp_ontario_currency
      self.currency = "CAD" if jurisdiction_code == "ON"
    end
  end
end
