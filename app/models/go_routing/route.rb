module GoRouting
  class Route < ApplicationRecord
    self.table_name = "go_routing_routes"
    MODES = %w[legacy shadow go].freeze

    validates :jurisdiction_code, inclusion: { in: RegistrationQuoteService::SUPPORTED_STATES }, uniqueness: true
    validates :mode, inclusion: { in: MODES }
  end
end
