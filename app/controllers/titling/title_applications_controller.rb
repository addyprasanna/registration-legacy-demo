module Titling
  class TitleApplicationsController < ApplicationController
    def index
      @title_applications = TitleApplication.includes(vehicle: :customer).order(created_at: :desc)
    end

    def show
      @title_application = TitleApplication.includes(vehicle: :customer).find(params[:id])
    end

    def new
      @vehicles = CustomerAccounts::Vehicle.includes(:customer).order(:vin)
    end

    def create
      vehicle = CustomerAccounts::Vehicle.find(params.require(:vehicle_id))
      code = vehicle.jurisdiction_code
      application = TitleApplication.create!(
        vehicle: vehicle,
        jurisdiction_code: code,
        application_number: "TA-#{code}-#{format('%06d', TitleApplication.count + 1)}",
        status: "draft",
        status_history: [{ "status" => "draft", "at" => Time.current.iso8601 }]
      )
      redirect_to title_application_path(application), notice: "Title application created."
    end

    def advance_status
      application = TitleApplication.find(params[:id])
      StatusTracker.new(application).advance!
      redirect_to title_application_path(application), notice: "Title application status advanced."
    rescue StatusTracker::LienPending => error
      redirect_to title_application_path(application), alert: error.message
    end
  end
end
