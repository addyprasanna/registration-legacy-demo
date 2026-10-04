require "json"

module GoRouting
  class QuoteRouter
    def self.call(params)
      legacy = RegistrationQuoteService.call(params)
      return legacy if ENV["GO_ROUTING_KILL_SWITCH"] == "1"

      jurisdiction_code = params.to_h.with_indifferent_access[:state].to_s.strip.upcase
      route = Route.find_by(jurisdiction_code: jurisdiction_code)
      return legacy unless route

      case route.mode
      when "shadow"
        ShadowCompareJob.perform_later(
          route.jurisdiction_code,
          params.to_h,
          Rack::Utils.status_code(legacy.status),
          legacy.body
        )
        legacy
      when "go"
        route_to_go(route, params.to_h, legacy)
      else
        legacy
      end
    end

    def self.comparison_outcome(legacy_status, legacy_body, go_status, go_body)
      return "not_migrated" if go_status == 501

      body_matches = go_status >= 500 || JSON.parse(JSON.generate(legacy_body)) == JSON.parse(JSON.generate(go_body))
      legacy_status == go_status && body_matches ? "matched" : "mismatched"
    end

    def self.record_comparison(route:, mode:, params:, legacy_status:, legacy_body:, go_status:, go_body:, outcome:, latency_ms:)
      Comparison.create!(
        jurisdiction_code: route.jurisdiction_code,
        mode: mode,
        outcome: outcome,
        legacy_status: legacy_status,
        go_status: go_status,
        request_params: params,
        legacy_body: legacy_body,
        go_body: go_body,
        latency_ms: latency_ms
      )
    end

    def self.route_to_go(route, params, legacy)
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      response = Client.call(params)
      latency_ms = elapsed_ms(started_at)
      legacy_status = Rack::Utils.status_code(legacy.status)
      outcome = comparison_outcome(legacy_status, legacy.body, response.status, response.body)
      record_comparison(
        route: route,
        mode: "go",
        params: params,
        legacy_status: legacy_status,
        legacy_body: legacy.body,
        go_status: response.status,
        go_body: response.body,
        outcome: outcome,
        latency_ms: latency_ms
      )
      return legacy if response.status == 501

      RegistrationQuoteService::Result.new(response.status, response.body)
    rescue Client::Unavailable
      record_comparison(
        route: route,
        mode: "go",
        params: params,
        legacy_status: Rack::Utils.status_code(legacy.status),
        legacy_body: legacy.body,
        go_status: nil,
        go_body: nil,
        outcome: "fallback",
        latency_ms: elapsed_ms(started_at)
      )
      legacy
    end

    def self.elapsed_ms(started_at)
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1_000).round
    end
    private_class_method :route_to_go, :elapsed_ms
  end
end
