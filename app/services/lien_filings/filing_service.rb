module LienFilings
  class FilingService
    def self.call(filing, at: Time.current)
      return filing if filing.status == "filed"

      Dmv::Gateway.submit("lien_filing", filing)
      from_status = filing.status
      LienFiling.transaction do
        filing.update!(status: "filed")
        ::StatusEvent.create!(
          vehicle: filing.vehicle,
          domain: "lien_filings",
          subject_type: filing.class.name,
          subject_id: filing.id,
          event: "filed",
          from_status: from_status,
          to_status: filing.status,
          occurred_at: at
        )
      end
      filing
    end
  end
end
