module TempTags
  class TempTag < ApplicationRecord
    self.table_name = "temp_tags"
    STATUSES = %w[active expired voided].freeze

    belongs_to :vehicle, class_name: "CustomerAccounts::Vehicle"
    validates :tag_number, presence: true, uniqueness: true
    validates :status, inclusion: { in: STATUSES }

    def status
      return "expired" if self[:status] == "active" && expires_on.present? && expires_on < Date.current

      self[:status]
    end
  end
end
