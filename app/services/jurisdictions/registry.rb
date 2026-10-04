module Jurisdictions
  module Registry
    CLASSES = {
      "CA" => California,
      "TX" => Texas,
      "FL" => Florida,
      "NY" => NewYork,
      "WA" => Washington,
      "ON" => Ontario,
      "DC" => DistrictOfColumbia,
      "AL" => Alabama, "AK" => Alaska, "AZ" => Arizona, "AR" => Arkansas,
      "CO" => Colorado, "CT" => Connecticut, "DE" => Delaware, "GA" => Georgia,
      "HI" => Hawaii, "ID" => Idaho, "IL" => Illinois, "IN" => Indiana,
      "IA" => Iowa, "KS" => Kansas, "KY" => Kentucky, "LA" => Louisiana,
      "ME" => Maine, "MD" => Maryland, "MA" => Massachusetts, "MI" => Michigan,
      "MN" => Minnesota, "MS" => Mississippi, "MO" => Missouri, "MT" => Montana,
      "NE" => Nebraska, "NV" => Nevada, "NH" => NewHampshire, "NJ" => NewJersey,
      "NM" => NewMexico, "NC" => NorthCarolina, "ND" => NorthDakota, "OH" => Ohio,
      "OK" => Oklahoma, "OR" => Oregon, "PA" => Pennsylvania, "RI" => RhodeIsland,
      "SC" => SouthCarolina, "SD" => SouthDakota, "TN" => Tennessee, "UT" => Utah,
      "VT" => Vermont, "VA" => Virginia, "WV" => WestVirginia, "WI" => Wisconsin,
      "WY" => Wyoming, "BC" => BritishColumbia, "QC" => Quebec
    }.freeze

    def self.for(code)
      normalized = code.to_s.strip.upcase
      CLASSES.fetch(normalized) { raise UnknownJurisdiction, normalized.presence || "(blank)" }
    end

    def self.all
      CLASSES.values
    end

    def self.codes
      CLASSES.keys
    end
  end

end
