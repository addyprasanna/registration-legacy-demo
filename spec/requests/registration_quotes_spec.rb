require "rails_helper"

RSpec.describe "POST /registration_quotes", type: :request do
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

  def post_quote(payload)
    post "/registration_quotes", params: payload.to_json, headers: { "CONTENT_TYPE" => "application/json" }
  end

  def set_ca_mode(mode)
    GoRouting::Route.find_or_initialize_by(jurisdiction_code: "CA").update!(mode: mode)
  end

  it "returns a California quote with the legacy response shape" do
    set_ca_mode("legacy")
    post_quote(valid_payload)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(
      "registration_fee_cents" => 8_500,
      "ev_surcharge_cents" => 10_000,
      "temp_tag_valid_days" => 90,
      "temp_tag_expires_on" => "2025-09-08",
      "lien_filing_required" => true,
      "lien_filing_method" => "electronic",
      "total_cents" => 18_500
    )
  end

  it "returns the legacy response and enqueues a comparison in shadow mode" do
    set_ca_mode("shadow")
    expected = RegistrationQuoteService.call(valid_payload).body.stringify_keys

    expect { post_quote(valid_payload) }.to have_enqueued_job(GoRouting::ShadowCompareJob)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(expected)
  end

  it "returns the Go response and records a matching comparison in Go mode" do
    set_ca_mode("go")
    legacy_body = RegistrationQuoteService.call(valid_payload).body.stringify_keys
    allow(GoRouting::Client).to receive(:call).and_return(
      GoRouting::Client::Response.new(status: 200, body: legacy_body)
    )

    post_quote(valid_payload)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(legacy_body)
    expect(GoRouting::Comparison.last).to have_attributes(outcome: "matched", mode: "go")
  end

  it "records a mismatch and returns the Go response in Go mode" do
    set_ca_mode("go")
    go_body = RegistrationQuoteService.call(valid_payload).body.stringify_keys.merge("total_cents" => 1)
    allow(GoRouting::Client).to receive(:call).and_return(
      GoRouting::Client::Response.new(status: 200, body: go_body)
    )

    post_quote(valid_payload)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(go_body)
    expect(GoRouting::Comparison.last).to have_attributes(outcome: "mismatched", mode: "go")
  end

  it "returns the legacy response and records a fallback when Go is unavailable" do
    set_ca_mode("go")
    expected = RegistrationQuoteService.call(valid_payload).body.stringify_keys
    allow(GoRouting::Client).to receive(:call).and_raise(GoRouting::Client::Unavailable)

    post_quote(valid_payload)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(expected)
    expect(GoRouting::Comparison.last).to have_attributes(outcome: "fallback", mode: "go")
  end

  it "returns the legacy response for a Go 501 result" do
    set_ca_mode("go")
    expected = RegistrationQuoteService.call(valid_payload).body.stringify_keys
    allow(GoRouting::Client).to receive(:call).and_return(
      GoRouting::Client::Response.new(status: 501, body: { "error" => "not migrated" })
    )

    post_quote(valid_payload)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(expected)
    expect(GoRouting::Comparison.last).to have_attributes(outcome: "not_migrated", mode: "go")
  end

  it "forces legacy routing when the kill switch is active" do
    set_ca_mode("go")
    expected = RegistrationQuoteService.call(valid_payload).body.stringify_keys
    original = ENV["GO_ROUTING_KILL_SWITCH"]
    ENV["GO_ROUTING_KILL_SWITCH"] = "1"

    expect(GoRouting::Client).not_to receive(:call)
    post_quote(valid_payload)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(expected)
    expect(GoRouting::Comparison.count).to eq(0)
  ensure
    ENV["GO_ROUTING_KILL_SWITCH"] = original
  end
end
