module OntarioRules
  extend ActiveSupport::Concern

  ONTARIO_FX_RATE = BigDecimal("1.35")
  ONTARIO_RST_RATE = BigDecimal("0.025")
  ONTARIO_EV_SURCHARGE_CENTS = 5_000
  ONTARIO_TEMP_TAG_DAYS = 40

  def ontario_price_cents_cad
    BigDecimal(price_cents.to_s) * ONTARIO_FX_RATE
  end

  def ontario_registration_fee_cents
    base = case vehicle_weight_lbs
           when 0...3300 then 5_900
           when 3300...5500 then 9_000
           else 12_000
           end
    base + ontario_rst_component_cents
  end

  def ontario_rst_component_cents
    ontario_round(ontario_price_cents_cad * ONTARIO_RST_RATE)
  end

  def ontario_ev_surcharge_cents
    ONTARIO_EV_SURCHARGE_CENTS
  end

  def ontario_temp_tag_valid_days
    ONTARIO_TEMP_TAG_DAYS
  end

  def ontario_temp_tag_expires_on
    delivery_date + ontario_temp_tag_valid_days
  end

  def ontario_lien_filing_method
    financing == "loan" || financing == "refinance" || financing == "lease" ? "electronic" : nil
  end

  def ontario_round(amount)
    BigDecimal(amount.to_s).round(0, :banker).to_i
  end
end
