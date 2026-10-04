module Jurisdictions
  def self.for(code)
    Registry.for(code)
  end

  def self.all
    Registry.all
  end

  def self.codes
    Registry.codes
  end
end
