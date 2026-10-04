require "rails_helper"

RSpec.describe GoRouting::ShadowCompareJob, type: :job do
  def valid_payload
    {
      state: "CA",
      vehicle_weight_lbs: 4_200,
      vehicle_price_usd: 48_990,
      financed: true,
      buyer_state: "CA",
      delivery_date: "2025-06-10"
    }
  end

  def legacy_body
    RegistrationQuoteService.call(valid_payload).body.stringify_keys
  end

  def set_ca_mode(mode)
    GoRouting::Route.find_or_initialize_by(jurisdiction_code: "CA").update!(mode: mode)
  end

  it "records an errored shadow comparison when Go is unavailable" do
    set_ca_mode("shadow")
    allow(GoRouting::Client).to receive(:call).and_raise(GoRouting::Client::Unavailable)

    described_class.perform_now("CA", valid_payload, 200, legacy_body)

    expect(GoRouting::Comparison.last).to have_attributes(
      outcome: "errored",
      mode: "shadow",
      go_status: nil
    )
  end

  it "records a matched shadow comparison when the bodies match" do
    set_ca_mode("shadow")
    allow(GoRouting::Client).to receive(:call).and_return(
      GoRouting::Client::Response.new(status: 200, body: legacy_body)
    )

    described_class.perform_now("CA", valid_payload, 200, legacy_body)

    expect(GoRouting::Comparison.last).to have_attributes(outcome: "matched", mode: "shadow")
  end

  it "records a mismatched shadow comparison when the bodies differ" do
    set_ca_mode("shadow")
    go_body = legacy_body.merge("total_cents" => 1)
    allow(GoRouting::Client).to receive(:call).and_return(
      GoRouting::Client::Response.new(status: 200, body: go_body)
    )

    described_class.perform_now("CA", valid_payload, 200, legacy_body)

    expect(GoRouting::Comparison.last).to have_attributes(outcome: "mismatched", mode: "shadow")
  end
end
