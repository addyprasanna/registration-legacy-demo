module GoRouting
  class RoutesController < ApplicationController
    def index
      @routes = RegistrationQuoteService::SUPPORTED_STATES.map do |code|
        Route.find_or_create_by!(jurisdiction_code: code)
      end
      @comparison_counts = Comparison.where(created_at: 24.hours.ago..Time.current).group(:jurisdiction_code, :outcome).count
      @recent_comparisons = Comparison.where(outcome: %w[mismatched errored]).order(created_at: :desc).limit(10)
      @kill_switch_active = ENV["GO_ROUTING_KILL_SWITCH"] == "1"
    end

    def update
      route = Route.find_by!(jurisdiction_code: params[:jurisdiction_code])
      route.update!(mode: params.require(:mode), updated_by: "ops-console")
      redirect_to go_routing_path, notice: "#{route.jurisdiction_code} routing mode updated."
    end

    def kill_all
      Route.where(jurisdiction_code: RegistrationQuoteService::SUPPORTED_STATES).update_all(
        mode: "legacy",
        updated_by: "ops-console",
        updated_at: Time.current
      )
      redirect_to go_routing_path, notice: "All routes set to legacy."
    end
  end
end
