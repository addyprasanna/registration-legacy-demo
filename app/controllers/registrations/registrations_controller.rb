module Registrations
  class RegistrationsController < ApplicationController
    def index
      @registrations = Registration.includes(vehicle: :customer).order(created_at: :desc)
      @registrations = @registrations.where(status: params[:status]) if params[:status].present?
      @registrations = @registrations.where(jurisdiction_code: params[:jurisdiction]) if params[:jurisdiction].present?
    end

    def show
      @registration = Registration.includes(vehicle: :customer).find(params[:id])
    end

    def new
      @registration = Registration.new
      @vehicles = CustomerAccounts::Vehicle.includes(:customer).order(:vin)
    end

    def create
      @registration = Registration.new
      vehicle = CustomerAccounts::Vehicle.find_by(id: params[:vehicle_id])
      unless vehicle
        @vehicle_error = "Select a vehicle."
        @vehicles = CustomerAccounts::Vehicle.includes(:customer).order(:vin)
        return render :new, status: :unprocessable_entity
      end

      quote = FeeCalculator.call(vehicle: vehicle)
      @registration = Registration.new(
        vehicle: vehicle,
        jurisdiction_code: vehicle.jurisdiction_code,
        status: "draft",
        currency: quote.jurisdiction.currency,
        fee_breakdown: quote.line_items.map { |item| { code: item.code, label: item.label, amount_cents: item.amount_cents } },
        registration_fee_cents: quote.registration_fee_cents,
        ev_surcharge_cents: quote.ev_surcharge_cents,
        total_cents: quote.total_cents
      )
      if @registration.save
        redirect_to registration_path(@registration), notice: "Registration quote created."
      else
        @vehicles = CustomerAccounts::Vehicle.includes(:customer).order(:vin)
        render :new, status: :unprocessable_entity
      end
    end

    def submit
      @registration = Registration.find(params[:id])
      SubmissionService.call(@registration)
      redirect_to registration_path(@registration), notice: "Registration submitted to DMV."
    end
  end
end
