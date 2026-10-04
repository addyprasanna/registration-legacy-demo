module TempTags
  class IssueService
    def self.call(vehicle:, issue_date: Date.current, buyer_jurisdiction: vehicle.jurisdiction_code, usage: vehicle.usage, valid_days: nil)
      input = Jurisdictions::QuoteInput.new(
        jurisdiction: vehicle.jurisdiction_code,
        weight_lbs: vehicle.weight_lbs,
        purchase_price_cents: vehicle.purchase_price_cents,
        powertrain: vehicle.powertrain,
        financing: vehicle.financing,
        lienholder_elt: vehicle.lienholder_elt,
        buyer_jurisdiction: buyer_jurisdiction,
        county: vehicle.county,
        usage: usage,
        delivery_date: issue_date
      )
      jurisdiction = Jurisdictions.for(vehicle.jurisdiction_code)
      default_days = jurisdiction.temp_tag_valid_days(input)
      tag_days = valid_days || default_days
      number = "#{vehicle.jurisdiction_code}-T-#{format('%06d', TempTags::TempTag.count + 1)}"
      TempTags::TempTag.create!(
        vehicle: vehicle,
        jurisdiction_code: vehicle.jurisdiction_code,
        tag_number: number,
        issued_on: issue_date,
        valid_days: tag_days,
        expires_on: jurisdiction.temp_tag_expires_on(input) + (tag_days - default_days),
        status: "active"
      )
    end
  end
end
