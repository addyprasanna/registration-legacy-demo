module DealerPortal
  class PendingRegistrationsQuery
    def self.call
      Delivery.includes(vehicle: :registrations)
              .where(status: %w[delivered scheduled])
              .select { |delivery| delivery.vehicle.registrations.none? { |registration| %w[submitted approved].include?(registration.status) } }
    end
  end
end
