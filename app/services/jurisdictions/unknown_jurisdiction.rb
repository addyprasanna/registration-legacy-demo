module Jurisdictions
  class UnknownJurisdiction < StandardError
    attr_reader :code

    def initialize(code)
      @code = code
      super("Unknown jurisdiction: #{code}")
    end
  end
end
