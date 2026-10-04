require "rails_helper"
require "rake"

RSpec.describe "demo:fresh_vehicle registration flow", type: :request do
  before(:all) do
    Rails.application.load_tasks unless Rake::Task.task_defined?("demo:fresh_vehicle")
  end

  it "creates a pending lien filing and a draft title application when the vehicle's registration is submitted" do
    expect { Rake::Task["demo:fresh_vehicle"].invoke }.to output(/vehicle_id=\d+/).to_stdout

    vehicle = CustomerAccounts::Vehicle.order(:id).last
    expect(vehicle.financing).to eq("loan")
    expect(vehicle.jurisdiction_code).to eq("CA")
    expect(vehicle.registrations).to be_empty
    expect(vehicle.lien_filings).to be_empty
    expect(vehicle.title_applications).to be_empty

    post registrations_path, params: { vehicle_id: vehicle.id }
    expect(response).to redirect_to(registration_path(Registrations::Registration.last))

    registration = Registrations::Registration.find_by!(vehicle: vehicle)
    expect(registration.status).to eq("draft")

    post submit_registration_path(registration)
    expect(response).to redirect_to(registration_path(registration))

    registration.reload
    expect(registration.status).to eq("submitted")
    expect(vehicle.lien_filings.where(status: "pending")).to exist
    expect(vehicle.title_applications.where(status: "draft")).to exist
  end
end
