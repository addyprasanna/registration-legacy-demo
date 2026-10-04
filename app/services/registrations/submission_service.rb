module Registrations
  class SubmissionService
    def self.call(registration, at: Time.current)
      confirmation = Dmv::Gateway.submit("registration", registration)
      from_status = registration.status
      Registration.transaction do
        registration.update!(
          status: "submitted",
          dmv_confirmation_number: confirmation,
          submitted_at: at
        )
        ::StatusEvent.create!(
          vehicle: registration.vehicle,
          domain: "registrations",
          subject_type: registration.class.name,
          subject_id: registration.id,
          event: "status_changed",
          from_status: from_status,
          to_status: registration.status,
          occurred_at: at
        )
      end
      registration
    end
  end
end
