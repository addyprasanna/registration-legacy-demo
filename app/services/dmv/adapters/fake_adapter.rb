require "digest"

module Dmv
  module Adapters
    class FakeAdapter
      def submit(kind, record)
        jurisdiction = record.jurisdiction_code
        digest = Digest::SHA256.hexdigest("#{record.id}:#{jurisdiction}")[0, 8].upcase
        Rails.logger.info("[FakeDMV] submitted #{kind} #{record.id}")
        "DMV-#{jurisdiction}-#{digest}"
      end
    end
  end
end
