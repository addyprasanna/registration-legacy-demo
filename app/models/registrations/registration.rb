module Registrations
  class Registration < ApplicationRecord
    self.table_name = "registrations"
    STATUSES = %w[draft submitted approved rejected].freeze

    belongs_to :vehicle, class_name: "CustomerAccounts::Vehicle"
    validates :status, inclusion: { in: STATUSES }
    before_save :stamp_ontario_currency

    private

    def stamp_ontario_currency
      self.currency = "CAD" if jurisdiction_code == "ON"
    end
  end
end
