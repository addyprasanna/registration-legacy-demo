class RegistrationQuoteService
  INPUT_FIELDS = %i[state vehicle_weight_lbs vehicle_price_usd financed buyer_state delivery_date].freeze
  SUPPORTED_STATES = Jurisdictions.codes.freeze
  Result = Struct.new(:status, :body)

  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @params = params.to_h.with_indifferent_access
  end

  def call
    state = @params[:state].to_s.strip.upcase
    unless SUPPORTED_STATES.include?(state)
      label = state.presence || "(blank)"
      return Result.new(:unprocessable_entity, { error: "Unknown jurisdiction: #{label}" })
    end

    @quote = RegistrationQuote.new(@params.slice(*INPUT_FIELDS))
    return Result.new(:unprocessable_entity, { error: "Invalid request", details: quote.errors.full_messages }) unless quote.valid?

    jurisdiction = Jurisdictions.for(state)
    input = Jurisdictions::QuoteInput.new(
      jurisdiction: state,
      weight_lbs: quote.vehicle_weight_lbs,
      purchase_price_cents: quote.round_cents(quote.price_cents),
      powertrain: "bev",
      financing: quote.financed? ? "loan" : "cash",
      lienholder_elt: true,
      buyer_jurisdiction: quote.buyer_state,
      county: nil,
      usage: "personal",
      delivery_date: quote.delivery_date
    )
    quote.registration_fee_cents = jurisdiction.registration_fee_cents(input)
    quote.ev_surcharge_cents = jurisdiction.ev_surcharge_cents(input)
    quote.temp_tag_valid_days = jurisdiction.temp_tag_valid_days(input)
    quote.temp_tag_expires_on = jurisdiction.temp_tag_expires_on(input)
    quote.lien_filing_required = jurisdiction.lien_filing_required?(input)
    quote.lien_filing_method = jurisdiction.lien_filing_method(input)
    Result.new(:ok, quote.to_response)
  end

  private

  attr_reader :quote

  def registration_fee_cents
    @registration_fee_cents
  end

  def ev_surcharge_cents
    @ev_surcharge_cents
  end

  def temp_tag_valid_days
    @temp_tag_valid_days
  end

  def temp_tag_expires_on
    @temp_tag_expires_on
  end

  def lien_filing_required
    @lien_filing_required
  end

  def lien_filing_method
    @lien_filing_method
  end
end
