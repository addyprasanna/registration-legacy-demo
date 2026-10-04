class RegistrationQuote
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :state, :string
  attribute :vehicle_weight_lbs, :integer
  attribute :vehicle_price_usd
  attribute :financed, :boolean, default: false
  attribute :buyer_state, :string
  attribute :delivery_date, :date
  attr_accessor :registration_fee_cents, :ev_surcharge_cents, :temp_tag_valid_days,
                :temp_tag_expires_on, :lien_filing_required, :lien_filing_method

  validates :vehicle_weight_lbs, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :vehicle_price_usd, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :delivery_date, presence: { message: "must be a valid YYYY-MM-DD date" }

  def state=(value)
    super(value.to_s.strip.upcase.presence)
  end

  def buyer_state=(value)
    super(value.to_s.strip.upcase.presence)
  end

  def buyer_state
    super || state
  end

  def financed?
    financed == true
  end

  def price_cents
    value = vehicle_price_usd.to_s.strip
    value = Integer(value, 0).to_s if value.match?(/\A[+-]?0x[0-9a-f]+\z/i)

    BigDecimal(value) * 100
  end

  def round_cents(amount)
    BigDecimal(amount.to_s).round(0, :half_up).to_i
  end

  def total_cents
    registration_fee_cents.to_i + ev_surcharge_cents.to_i
  end

  def plate_transfer_credit_cents(previous_registration_fee_cents)
    return 0 if previous_registration_fee_cents.to_i <= 0

    round_cents(previous_registration_fee_cents * BigDecimal("0.25"))
  end

  def to_response
    {
      registration_fee_cents: registration_fee_cents,
      ev_surcharge_cents: ev_surcharge_cents,
      temp_tag_valid_days: temp_tag_valid_days,
      temp_tag_expires_on: temp_tag_expires_on&.iso8601,
      lien_filing_required: lien_filing_required,
      lien_filing_method: lien_filing_method,
      total_cents: total_cents
    }
  end
end
