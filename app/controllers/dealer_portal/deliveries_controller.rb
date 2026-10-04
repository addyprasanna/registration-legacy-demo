module DealerPortal
  class DeliveriesController < ApplicationController
    def index
      @deliveries = PendingRegistrationsQuery.call
    end
  end
end
