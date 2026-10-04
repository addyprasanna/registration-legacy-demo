require "rails_helper"

RSpec.describe "Go routing console", type: :request do
  def route_for(code, mode:)
    GoRouting::Route.find_or_initialize_by(jurisdiction_code: code).tap do |route|
      route.update!(mode: mode)
    end
  end

  it "sets the CA route to legacy from the per-route kill switch" do
    route = route_for("CA", mode: "go")

    patch "/go_routing/CA", params: { mode: "legacy" }

    expect(response).to have_http_status(:redirect)
    expect(route.reload).to have_attributes(mode: "legacy", updated_by: "ops-console")
  end

  it "sets every route to legacy from the global kill switch" do
    ca_route = route_for("CA", mode: "go")
    other_code = RegistrationQuoteService::SUPPORTED_STATES.find { |code| code != "CA" }
    other_route = route_for(other_code, mode: "go")

    post "/go_routing/kill_all"

    expect(response).to have_http_status(:redirect)
    expect(GoRouting::Route.where.not(mode: "legacy")).to be_empty
    expect([ca_route.reload, other_route.reload]).to all(
      have_attributes(mode: "legacy", updated_by: "ops-console")
    )
  end

  it "shows the kill-switch banner when the environment setting is active" do
    original = ENV["GO_ROUTING_KILL_SWITCH"]
    ENV["GO_ROUTING_KILL_SWITCH"] = "1"

    get "/go_routing"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("The GO_ROUTING_KILL_SWITCH environment setting is active.")
  ensure
    ENV["GO_ROUTING_KILL_SWITCH"] = original
  end
end
