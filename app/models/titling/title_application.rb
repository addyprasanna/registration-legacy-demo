module Titling
  class TitleApplication < ApplicationRecord
    self.table_name = "title_applications"
    STATUSES = %w[draft submitted in_review issued rejected].freeze

    belongs_to :vehicle, class_name: "CustomerAccounts::Vehicle"
    validates :application_number, presence: true, uniqueness: true
    validates :status, inclusion: { in: STATUSES }
  end
end
