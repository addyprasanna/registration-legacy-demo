module Registrations
  class SubmissionService
    def self.call(registration, at: Time.current)
      confirmation = Dmv::Gateway.submit("registration", registration)
      registration.update!(
        status: "submitted",
        dmv_confirmation_number: confirmation,
        submitted_at: at
      )
      registration
    end
  end
end
