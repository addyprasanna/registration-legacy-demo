module Api
  module V1
    class JurisdictionsController < BaseController
      def index
        render_data(Jurisdictions.all.map { |jurisdiction| jurisdiction.metadata.slice(:code, :name, :country, :currency, :tier) })
      end

      def show
        render_data(Jurisdictions.for(params[:code]).metadata)
      end
    end
  end
end
