require "rails_helper"
require "socket"

RSpec.describe GoRouting::Client do
  def with_go_url(url)
    original = ENV["REGISTRATION_GO_URL"]
    ENV["REGISTRATION_GO_URL"] = url
    yield
  ensure
    ENV["REGISTRATION_GO_URL"] = original
  end

  def stub_http_start(result)
    http = instance_double(Net::HTTP)
    allow(Net::HTTP).to receive(:new).and_return(http)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:open_timeout=)
    allow(http).to receive(:read_timeout=)
    allow(http).to receive(:start).and_return(result)
    http
  end

  it "raises Unavailable when the Go connection is refused" do
    server = TCPServer.new("127.0.0.1", 0)
    port = server.addr[1]
    server.close

    expect do
      with_go_url("http://127.0.0.1:#{port}") do
        described_class.call(state: "CA")
      end
    end.to raise_error(GoRouting::Client::Unavailable)
  ensure
    server&.close unless server&.closed?
  end

  it "raises Unavailable on an open timeout" do
    http = stub_http_start(nil)
    allow(http).to receive(:start).and_raise(Net::OpenTimeout)

    expect do
      with_go_url("http://127.0.0.1:8080") { described_class.call(state: "CA") }
    end.to raise_error(GoRouting::Client::Unavailable)
  end

  it "raises Unavailable on a read timeout" do
    http = stub_http_start(nil)
    allow(http).to receive(:start).and_raise(Net::ReadTimeout)

    expect do
      with_go_url("http://127.0.0.1:8080") { described_class.call(state: "CA") }
    end.to raise_error(GoRouting::Client::Unavailable)
  end

  it "raises Unavailable when the response body is not JSON" do
    http = stub_http_start(double(code: "200", body: "<html>"))

    expect do
      with_go_url("http://127.0.0.1:8080") { described_class.call(state: "CA") }
    end.to raise_error(GoRouting::Client::Unavailable)
  end

  it "returns a response with an integer status and parsed JSON body" do
    http = stub_http_start(double(code: "200", body: '{"total_cents":18500}'))

    result = with_go_url("http://127.0.0.1:8080") do
      described_class.call(state: "CA")
    end

    expect(result).to be_a(GoRouting::Client::Response)
    expect(result.status).to be_an(Integer)
    expect(result).to have_attributes(status: 200, body: { "total_cents" => 18_500 })
  end
end
