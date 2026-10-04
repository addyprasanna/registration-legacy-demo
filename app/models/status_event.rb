class StatusEvent < ApplicationRecord
  belongs_to :vehicle, class_name: "CustomerAccounts::Vehicle"

  validates :domain, inclusion: { in: %w[registrations titling lien_filings temp_tags] }
  validates :event, :occurred_at, presence: true
end
