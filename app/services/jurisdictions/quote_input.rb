module Jurisdictions
  class QuoteInput
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :jurisdiction, :string
    attribute :weight_lbs, :integer
    attribute :purchase_price_cents, :integer
    attribute :powertrain, :string, default: "bev"
    attribute :financing, :string, default: "cash"
    attribute :lienholder_elt, :boolean, default: true
    attribute :buyer_jurisdiction, :string
    attribute :county, :string
    attribute :usage, :string, default: "personal"
    attribute :delivery_date, :date

    def jurisdiction=(value)
      super(value.to_s.strip.upcase.presence)
    end

    def buyer_jurisdiction=(value)
      super(value.to_s.strip.upcase.presence)
    end

    def buyer_jurisdiction
      super || jurisdiction
    end

    def county=(value)
      super(value.to_s.strip.upcase.presence)
    end

    def financed?
      %w[loan refinance].include?(financing)
    end

    def lease?
      financing == "lease"
    end

    def refinance?
      financing == "refinance"
    end

    def out_of_state_buyer?
      buyer_jurisdiction != jurisdiction
    end

    def price_cents
      purchase_price_cents.to_i
    end
  end
end
