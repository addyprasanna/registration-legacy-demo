module LienFilings
  class DeterminationService
    Result = Struct.new(:jurisdiction, :input, :required, :filing_method, :reason, keyword_init: true)

    def self.call(input)
      jurisdiction = Jurisdictions.for(input.jurisdiction)
      Result.new(
        jurisdiction: jurisdiction,
        input: input,
        required: jurisdiction.lien_filing_required?(input),
        filing_method: jurisdiction.lien_filing_method(input),
        reason: jurisdiction.lien_reason(input)
      )
    end
  end
end
