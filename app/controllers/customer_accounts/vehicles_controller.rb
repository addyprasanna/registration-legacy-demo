module CustomerAccounts
  class VehiclesController < ApplicationController
    def show
      @vehicle = Vehicle.includes(:customer, :registrations, :temp_tags, :lien_filings, :title_applications, :deliveries).find(params[:id])
      @status_events = @vehicle.status_events.order(occurred_at: :desc)
    end
  end
end
