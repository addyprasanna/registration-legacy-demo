module CustomerAccounts
  class Vehicle < ApplicationRecord
    self.table_name = "customer_accounts_vehicles"
    WA_RTA_COUNTIES = %w[KING PIERCE SNOHOMISH].freeze
    MODELS = ["Air Pure", "Air Touring", "Air Grand Touring", "Air Sapphire", "Gravity Touring", "Gravity Grand Touring"].freeze

    belongs_to :customer, class_name: "CustomerAccounts::Customer"
    has_many :registrations, class_name: "Registrations::Registration", dependent: :destroy
    has_many :temp_tags, class_name: "TempTags::TempTag", dependent: :destroy
    has_many :lien_filings, class_name: "LienFilings::LienFiling", dependent: :destroy
    has_many :title_applications, class_name: "Titling::TitleApplication", dependent: :destroy
    has_many :deliveries, class_name: "DealerPortal::Delivery", dependent: :destroy

    validates :vin, presence: true, uniqueness: true, format: { with: /\A(?!.*[IOQ])[A-HJ-NPR-Z0-9]{17}\z/ }
    validates :model, inclusion: { in: MODELS }
    validates :weight_lbs, :purchase_price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :powertrain, inclusion: { in: %w[bev phev ice] }
    validates :financing, inclusion: { in: %w[cash loan lease refinance] }
    validates :usage, inclusion: { in: %w[personal commercial] }

    def jurisdiction_code
      customer&.jurisdiction_code
    end
  end
end
