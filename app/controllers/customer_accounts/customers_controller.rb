module CustomerAccounts
  class CustomersController < ApplicationController
    def index
      @customers = Customer.includes(:vehicles).order(:last_name, :first_name)
      @customers = @customers.where(jurisdiction_code: params[:jurisdiction]) if params[:jurisdiction].present?
      if params[:q].present?
        term = "%#{params[:q].strip}%"
        @customers = @customers.where("first_name LIKE :term OR last_name LIKE :term OR email LIKE :term OR customer_number LIKE :term", term: term)
      end
    end

    def show
      @customer = Customer.includes(vehicles: %i[registrations temp_tags lien_filings title_applications]).find(params[:id])
    end

    def new
      @customer = Customer.new
    end

    def create
      @customer = Customer.new(customer_params)
      if @customer.save
        redirect_to customer_path(@customer), notice: "Customer created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @customer = Customer.find(params[:id])
    end

    def update
      @customer = Customer.find(params[:id])
      if @customer.update(customer_params)
        redirect_to customer_path(@customer), notice: "Customer updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def customer_params
      params.require(:customer).permit(:customer_number, :first_name, :last_name, :email, :phone, :address_line1, :city, :jurisdiction_code, :postal_code)
    end
  end
end
