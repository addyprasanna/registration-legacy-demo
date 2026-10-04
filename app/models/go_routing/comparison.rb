module GoRouting
  class Comparison < ApplicationRecord
    self.table_name = "go_routing_comparisons"
    OUTCOMES = %w[matched mismatched not_migrated errored fallback].freeze

    validates :jurisdiction_code, inclusion: { in: RegistrationQuoteService::SUPPORTED_STATES }
    validates :mode, inclusion: { in: Route::MODES }
    validates :outcome, inclusion: { in: OUTCOMES }
  end
end
