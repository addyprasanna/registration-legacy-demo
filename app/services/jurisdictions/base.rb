module Jurisdictions
  LineItem = Struct.new(:code, :label, :amount_cents, keyword_init: true)

  class Base
    def self.code
      Registry::CLASSES.key(self)
    end

    def self.display_name
      const_get(:NAME)
    end

    def self.country
      const_get(:COUNTRY)
    end

    def self.currency
      const_get(:CURRENCY)
    end

    def self.tier
      const_get(:TIER)
    end

    def self.fee_line_items(input)
      []
    end

    def self.registration_fee_cents(input)
      fee_line_items(input).reject { |item| item.code == "ev_surcharge" }.sum(&:amount_cents)
    end

    def self.ev_surcharge_cents(input)
      fee_line_items(input).find { |item| item.code == "ev_surcharge" }&.amount_cents.to_i
    end

    def self.total_cents(input)
      fee_line_items(input).sum(&:amount_cents)
    end

    def self.temp_tag_valid_days(input)
      const_get(:TEMP_TAG_DAYS)
    end

    def self.temp_tag_expires_on(input)
      input.delivery_date + temp_tag_valid_days(input)
    end

    def self.elt_available?
      const_get(:ELT)
    end

    def self.lease_lien_required?
      const_get(:LEASE_LIEN_REQUIRED)
    end

    def self.lien_filing_required?(input)
      input.financed? || (input.lease? && lease_lien_required?)
    end

    def self.lien_filing_method(input)
      return unless lien_filing_required?(input)

      elt_available? && input.lienholder_elt ? "electronic" : "paper"
    end

    def self.lien_reason(input)
      return "No lien to record" unless lien_filing_required?(input)
      return "Electronic filing via #{display_name} ELT" if lien_filing_method(input) == "electronic"

      "Paper filing with #{display_name} motor vehicle agency"
    end

    def self.title_fee_cents
      const_get(:TITLE_FEE_CENTS)
    end

    def self.weight_tier_label(weight)
      tiers = const_get(:WEIGHT_TIERS)
      previous = 0
      tiers.each do |maximum, _amount|
        return maximum ? "#{previous + 1}–#{maximum} lbs" : "Over #{previous} lbs" if maximum.nil? || weight <= maximum

        previous = maximum
      end
    end

    def self.weight_tiers
      const_get(:WEIGHT_TIERS)
    end

    def self.metadata
      {
        code: code,
        name: display_name,
        country: country,
        currency: currency,
        tier: tier,
        weight_tiers: weight_tiers,
        ev_surcharge_cents: const_defined?(:EV_SURCHARGE_CENTS) ? const_get(:EV_SURCHARGE_CENTS) : nil,
        temp_tag_days: const_get(:TEMP_TAG_DAYS),
        elt: elt_available?
      }
    end

    def self.round_cents(value, mode = :half_up)
      BigDecimal(value.to_s).round(0, mode).to_i
    end

    def self.money_item(code, label, amount)
      LineItem.new(code: code, label: label, amount_cents: amount.to_i) if amount.to_i.positive?
    end
  end

end
