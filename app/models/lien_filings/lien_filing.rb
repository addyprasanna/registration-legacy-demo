module LienFilings
  class LienFiling < ApplicationRecord
    self.table_name = "lien_filings"
    STATUSES = %w[not_required pending filed released].freeze

    belongs_to :vehicle, class_name: "CustomerAccounts::Vehicle"
    validates :status, inclusion: { in: STATUSES }
  end
end
