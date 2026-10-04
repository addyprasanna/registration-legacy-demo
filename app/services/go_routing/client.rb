require "json"
require "net/http"
require "uri"

module GoRouting
  class Client
    Response = Struct.new(:status, :body, keyword_init: true)

    class Unavailable < StandardError; end

    def self.call(params)
      uri = URI("#{ENV.fetch('REGISTRATION_GO_URL', 'http://127.0.0.1:8080').chomp('/')}/registration_quotes")
      http = Net::HTTP.new(uri.host, uri.port, nil)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 0.5
      http.read_timeout = 0.5
      request = Net::HTTP::Post.new(uri.request_uri, "Content-Type" => "application/json")
      request.body = params.to_h.to_json
      response = http.start { |connection| connection.request(request) }
      Response.new(status: response.code.to_i, body: JSON.parse(response.body.presence || "null"))
    rescue Timeout::Error, SocketError, SystemCallError, IOError, EOFError, Net::HTTPBadResponse, JSON::ParserError => error
      raise Unavailable, error.message
    end
  end
end
