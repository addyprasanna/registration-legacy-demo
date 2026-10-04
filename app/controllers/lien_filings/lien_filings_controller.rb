module LienFilings
  class LienFilingsController < ApplicationController
    def index
      @lien_filings = LienFiling.includes(vehicle: :customer).order(created_at: :desc)
    end

    def show
      @lien_filing = LienFiling.includes(vehicle: :customer).find(params[:id])
    end

    def new
      @vehicles = CustomerAccounts::Vehicle.includes(:customer).order(:vin)
      @lien_filing = LienFiling.new
    end

    def create
      vehicle = CustomerAccounts::Vehicle.includes(:customer).find(params.require(:vehicle_id))
      input = Jurisdictions::QuoteInput.new(
        jurisdiction: vehicle.jurisdiction_code,
        financing: vehicle.financing,
        lienholder_elt: vehicle.lienholder_elt,
        buyer_jurisdiction: params[:buyer_jurisdiction].presence || vehicle.jurisdiction_code
      )
      determination = DeterminationService.call(input)
      @lien_filing = LienFiling.create!(
        vehicle: vehicle,
        jurisdiction_code: vehicle.jurisdiction_code,
        financing: vehicle.financing,
        lienholder_name: vehicle.lienholder_name,
        elt_participant: vehicle.lienholder_elt,
        required: determination.required,
        filing_method: determination.filing_method,
        reason: determination.reason,
        status: determination.required ? "pending" : "not_required"
      )
      redirect_to lien_filing_path(@lien_filing), notice: "Lien determination recorded."
    end

    def file
      @lien_filing = LienFiling.find(params[:id])
      FilingService.call(@lien_filing)
      redirect_to lien_filing_path(@lien_filing), notice: "Lien filing sent to DMV."
    end
  end
end
