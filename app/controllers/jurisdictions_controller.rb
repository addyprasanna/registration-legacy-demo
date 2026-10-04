class JurisdictionsController < ApplicationController
  def index
    @jurisdictions = Jurisdictions.all.sort_by(&:display_name)
  end

  def show
    @jurisdiction = Jurisdictions.for(params[:code])
  end
end
