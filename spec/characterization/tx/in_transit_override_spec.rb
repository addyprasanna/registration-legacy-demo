require "rails_helper"

RSpec.describe TexasInTransitOverride do
  subject(:host) { Class.new { include TexasInTransitOverride }.new }

  def input(**attributes)
    Jurisdictions::QuoteInput.new({
      jurisdiction: "TX",
      weight_lbs: 4_200,
      purchase_price_cents: 4_899_000,
      delivery_date: Date.new(2025, 6, 10)
    }.merge(attributes))
  end

  it "is included by both temp tag controllers" do
    expect(Api::V1::TempTagsController.ancestors).to include(described_class)
    expect(TempTags::TempTagsController.ancestors).to include(described_class)
  end

  describe "#temp_tag_days_for with Jurisdictions::Texas" do
    let(:texas) { Jurisdictions::Texas }

    it "returns 30 for an out-of-state buyer" do
      %w[CA OK ON ZZ].each do |buyer|
        expect(host.temp_tag_days_for(texas, input(buyer_jurisdiction: buyer))).to eq(30)
      end
    end

    it "delegates to Texas for an in-state buyer, which returns 60" do
      [nil, "", "TX", " tx "].each do |buyer|
        expect(host.temp_tag_days_for(texas, input(buyer_jurisdiction: buyer))).to eq(60)
      end
    end

    it "ignores usage" do
      expect(host.temp_tag_days_for(texas, input(usage: "commercial"))).to eq(60)
      expect(host.temp_tag_days_for(texas, input(usage: "commercial", buyer_jurisdiction: "CA"))).to eq(30)
    end

    it "decides out-of-state from the input's jurisdiction, not from TX" do
      expect(host.temp_tag_days_for(texas, input(jurisdiction: "CA", buyer_jurisdiction: "TX"))).to eq(30)
      expect(host.temp_tag_days_for(texas, input(jurisdiction: "CA"))).to eq(60)
    end

    it "returns the same value as Jurisdictions::Texas.temp_tag_valid_days for every buyer combination" do
      [nil, "TX", "CA", "ON"].each do |buyer|
        %w[personal commercial].each do |usage|
          quote = input(buyer_jurisdiction: buyer, usage: usage)
          expect(host.temp_tag_days_for(texas, quote)).to eq(texas.temp_tag_valid_days(quote))
        end
      end
    end
  end

  describe "#temp_tag_days_for short-circuit" do
    it "returns 30 without consulting a jurisdiction whose code is exactly TX when the buyer is out of state" do
      jurisdiction = double("jurisdiction", code: "TX")
      expect(jurisdiction).not_to receive(:temp_tag_valid_days)

      expect(host.temp_tag_days_for(jurisdiction, input(buyer_jurisdiction: "CA"))).to eq(30)
    end

    it "delegates to a TX-coded jurisdiction for in-state buyers" do
      jurisdiction = double("jurisdiction", code: "TX", temp_tag_valid_days: 99)

      expect(host.temp_tag_days_for(jurisdiction, input)).to eq(99)
    end

    it "delegates when the jurisdiction code is not exactly TX" do
      %w[tx CA].each do |code|
        jurisdiction = double("jurisdiction", code: code, temp_tag_valid_days: 99)
        expect(host.temp_tag_days_for(jurisdiction, input(buyer_jurisdiction: "CA"))).to eq(99)
      end
    end

    it "delegates for non-Texas jurisdictions even when the input is a Texas sale to an out-of-state buyer" do
      quote = input(buyer_jurisdiction: "CA")
      expect(host.temp_tag_days_for(Jurisdictions::California, quote)).to eq(Jurisdictions::California.temp_tag_valid_days(quote))
      expect(host.temp_tag_days_for(Jurisdictions::California, quote)).to eq(90)
    end
  end

  describe "through the temp tag endpoints", type: :request do
    let!(:customer) do
      CustomerAccounts::Customer.create!(
        customer_number: "LC-TX-CHAR-1",
        first_name: "Jordan",
        last_name: "Hale",
        email: "jordan.hale.tx-char@example.test",
        jurisdiction_code: "TX"
      )
    end
    let!(:vehicle) do
      CustomerAccounts::Vehicle.create!(
        customer: customer,
        vin: "5LVTXCHAR00000001",
        model: "Air Touring",
        model_year: 2025,
        weight_lbs: 4_200,
        purchase_price_cents: 4_899_000,
        powertrain: "bev",
        financing: "cash",
        usage: "personal",
        delivery_date: Date.new(2025, 6, 10)
      )
    end
    let(:headers) { { "CONTENT_TYPE" => "application/json" } }

    def issue_api(**body)
      post "/api/v1/temp_tags", params: { vin: vehicle.vin, issue_date: "2025-06-10" }.merge(body).to_json, headers: headers
      expect(response).to have_http_status(:created)
      response.parsed_body["data"]
    end

    it "issues a 60-day API tag when buyer_jurisdiction is omitted or TX" do
      [{}, { buyer_jurisdiction: "TX" }, { buyer_jurisdiction: " tx " }].each do |body|
        data = issue_api(**body)
        expect(data).to include("jurisdiction" => "TX", "issued_on" => "2025-06-10", "valid_days" => 60, "expires_on" => "2025-08-09")
      end
    end

    it "issues a 30-day API tag for an out-of-state buyer" do
      [{ buyer_jurisdiction: "CA" }, { buyer_jurisdiction: " ok " }, { buyer_jurisdiction: "ON", usage: "commercial" }].each do |body|
        data = issue_api(**body)
        expect(data).to include("jurisdiction" => "TX", "valid_days" => 30, "expires_on" => "2025-07-10")
      end
    end

    it "rejects an unregistered buyer_jurisdiction on the API" do
      post "/api/v1/temp_tags", params: { vin: vehicle.vin, issue_date: "2025-06-10", buyer_jurisdiction: "ZZ" }.to_json, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "code")).to eq("unknown_jurisdiction")
    end

    it "issues HTML tags with 60 days in state and 30 days out of state" do
      post "/temp_tags", params: { vehicle_id: vehicle.id, issue_date: "2025-06-10" }
      in_state = vehicle.temp_tags.order(:id).last
      expect(response).to redirect_to(temp_tag_path(in_state))
      expect([in_state.valid_days, in_state.expires_on]).to eq([60, Date.new(2025, 8, 9)])

      post "/temp_tags", params: { vehicle_id: vehicle.id, issue_date: "2025-06-10", buyer_jurisdiction: "ca" }
      out_of_state = vehicle.temp_tags.order(:id).last
      expect(response).to redirect_to(temp_tag_path(out_of_state))
      expect([out_of_state.valid_days, out_of_state.expires_on]).to eq([30, Date.new(2025, 7, 10)])
    end
  end
end
