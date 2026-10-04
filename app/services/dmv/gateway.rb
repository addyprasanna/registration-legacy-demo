module Dmv
  class Gateway
    def self.submit(kind, record)
      adapter = Rails.configuration.x.dmv_adapter
      raise ArgumentError, "Unsupported DMV adapter: #{adapter}" unless adapter.to_sym == :fake

      Adapters::FakeAdapter.new.submit(kind, record)
    end
  end
end
