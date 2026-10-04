module GoRouting
  class ShadowCompareJob < ApplicationJob
    queue_as :default

    def perform(jurisdiction_code, params, legacy_status, legacy_body)
      route = Route.find_by!(jurisdiction_code: jurisdiction_code)
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      response = Client.call(params)
      latency_ms = elapsed_ms(started_at)
      outcome = QuoteRouter.comparison_outcome(legacy_status, legacy_body, response.status, response.body)
      QuoteRouter.record_comparison(
        route: route,
        mode: "shadow",
        params: params,
        legacy_status: legacy_status,
        legacy_body: legacy_body,
        go_status: response.status,
        go_body: response.body,
        outcome: outcome,
        latency_ms: latency_ms
      )
    rescue Client::Unavailable
      QuoteRouter.record_comparison(
        route: route,
        mode: "shadow",
        params: params,
        legacy_status: legacy_status,
        legacy_body: legacy_body,
        go_status: nil,
        go_body: nil,
        outcome: "errored",
        latency_ms: elapsed_ms(started_at)
      )
    end

    private

    def elapsed_ms(started_at)
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1_000).round
    end
  end
end
