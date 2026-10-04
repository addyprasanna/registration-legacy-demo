module CustomerAccounts
  class Customer < ApplicationRecord
    self.table_name = "customer_accounts_customers"

    has_many :vehicles, class_name: "CustomerAccounts::Vehicle", foreign_key: :customer_id, dependent: :destroy
    validates :customer_number, :first_name, :last_name, :email, :jurisdiction_code, presence: true
    validates :customer_number, :email, uniqueness: true
    validates :jurisdiction_code, inclusion: { in: ->(_) { Jurisdictions.codes } }

    def display_name
      "#{first_name} #{last_name}"
    end
  end
end
