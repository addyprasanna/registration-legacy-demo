module TempTags
  class TempTagsController < ApplicationController
    include TexasInTransitOverride

    def index
      @temp_tags = TempTag.includes(vehicle: :customer).order(expires_on: :asc)
      @temp_tags = @temp_tags.where(expires_on: Date.current..7.days.from_now.to_date) if params[:expiring_soon].present?
    end

    def show
      @temp_tag = TempTag.includes(vehicle: :customer).find(params[:id])
    end

    def new
      @vehicles = CustomerAccounts::Vehicle.includes(:customer).order(:vin)
    end

    def create
      vehicle = CustomerAccounts::Vehicle.find_by(id: params[:vehicle_id])
      unless vehicle
        @vehicle_error = "Select a vehicle."
        @vehicles = CustomerAccounts::Vehicle.includes(:customer).order(:vin)
        return render :new, status: :unprocessable_entity
      end

      issue_date = params[:issue_date].present? ? Date.iso8601(params[:issue_date]) : Date.current
      input = Jurisdictions::QuoteInput.new(
        jurisdiction: vehicle.jurisdiction_code,
        weight_lbs: vehicle.weight_lbs,
        purchase_price_cents: vehicle.purchase_price_cents,
        buyer_jurisdiction: params[:buyer_jurisdiction].presence || vehicle.jurisdiction_code,
        usage: vehicle.usage,
        delivery_date: issue_date
      )
      days = temp_tag_days_for(Jurisdictions.for(vehicle.jurisdiction_code), input)
      @temp_tag = IssueService.call(vehicle: vehicle, issue_date: issue_date, buyer_jurisdiction: input.buyer_jurisdiction, valid_days: days)
      redirect_to temp_tag_path(@temp_tag), notice: "Temporary tag issued."
    end

    def void
      @temp_tag = TempTag.find(params[:id])
      @temp_tag.update!(status: "voided")
      redirect_to temp_tag_path(@temp_tag), notice: "Temporary tag voided."
    end
  end
end
