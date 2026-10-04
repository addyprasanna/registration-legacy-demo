class RegistrationQuotesController < ActionController::API
  wrap_parameters false

  def create
    result = GoRouting::QuoteRouter.call(quote_params)
    render json: result.body, status: result.status
  end

  private

  def quote_params
    params.permit(*RegistrationQuoteService::INPUT_FIELDS).to_h
  end
end
