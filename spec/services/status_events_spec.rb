require "rails_helper"

RSpec.describe "Status event flows" do
  let(:vehicle) do
    customer = CustomerAccounts::Customer.create!(
      customer_number: "SPEC-CA-001",
      first_name: "Casey",
      last_name: "Tester",
      email: "casey.tester@example.com",
      jurisdiction_code: "CA"
    )
    CustomerAccounts::Vehicle.create!(
      customer: customer,
      vin: "5LV00000000000000",
      model: "Air Pure",
      model_year: 2026,
      weight_lbs: 4_600,
      purchase_price_cents: 10_000_000,
      financing: "loan",
      lienholder_name: "California Finance",
      lienholder_elt: true,
      delivery_date: Date.new(2026, 10, 4)
    )
  end

  it "creates a pending lien and draft title on submission and blocks issuance until filing" do
    quote = Registrations::FeeCalculator.call(vehicle: vehicle)
    registration = Registrations::Registration.create!(
      vehicle: vehicle,
      jurisdiction_code: "CA",
      status: "draft",
      currency: quote.jurisdiction.currency,
      fee_breakdown: quote.line_items.map { |item| { code: item.code, label: item.label, amount_cents: item.amount_cents } },
      registration_fee_cents: quote.registration_fee_cents,
      ev_surcharge_cents: quote.ev_surcharge_cents,
      total_cents: quote.total_cents
    )
    at = Time.utc(2026, 10, 4, 12)

    Registrations::SubmissionService.call(registration, at: at)

    filing = vehicle.lien_filings.find_by!(status: "pending")
    application = vehicle.title_applications.find_by!(status: "draft")
    expect(vehicle.status_events.pluck(:domain)).to contain_exactly("registrations", "lien_filings", "titling")

    tracker = Titling::StatusTracker.new(application)
    tracker.advance!(at: at + 1)
    tracker.advance!(at: at + 2)
    expect(application.reload.status).to eq("in_review")
    expect { tracker.advance!(at: at + 3) }.to raise_error(
      Titling::StatusTracker::LienPending,
      "Title can't be issued while a lien filing is pending."
    )

    LienFilings::FilingService.call(filing, at: at + 4)
    tracker.advance!(at: at + 5)

    expect(filing.reload.status).to eq("filed")
    expect(application.reload.status).to eq("issued")
    expect(vehicle.status_events.where(domain: "lien_filings", event: "filed").count).to eq(1)
  end

  it "marks scheduled delivery complete when a California temporary tag is issued" do
    delivery = DealerPortal::Delivery.create!(
      vehicle: vehicle,
      delivery_center: "Newark, CA",
      scheduled_on: vehicle.delivery_date,
      status: "scheduled"
    )
    at = Time.utc(2026, 10, 4, 13)

    tag = TempTags::IssueService.call(vehicle: vehicle, issue_date: vehicle.delivery_date, at: at)

    expect(delivery.reload.status).to eq("delivered")
    expect(vehicle.status_events.find_by!(domain: "temp_tags", subject_id: tag.id)).to have_attributes(
      event: "issued",
      to_status: "active",
      occurred_at: at
    )
  end
end
