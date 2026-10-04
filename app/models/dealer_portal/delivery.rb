module DealerPortal
  class Delivery < ApplicationRecord
    self.table_name = "dealer_portal_deliveries"

    belongs_to :vehicle, class_name: "CustomerAccounts::Vehicle"
    validates :delivery_center, :scheduled_on, presence: true
    validates :status, inclusion: { in: %w[scheduled delivered] }
  end
end
