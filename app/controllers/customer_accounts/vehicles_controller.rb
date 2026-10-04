module CustomerAccounts
  class VehiclesController < ApplicationController
    def show
      @vehicle = Vehicle.includes(:customer, :registrations, :temp_tags, :lien_filings, :title_applications, :deliveries).find(params[:id])
    end
  end
end
