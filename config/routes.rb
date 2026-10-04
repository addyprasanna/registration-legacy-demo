Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resources :registration_quotes, only: :create

  root "dashboard#show"
  scope module: :customer_accounts do
    resources :customers
    resources :vehicles, only: :show
  end
  scope module: :registrations do
    resources :registrations do
      post :submit, on: :member
    end
  end
  scope module: :temp_tags do
    resources :temp_tags do
      post :void, on: :member
    end
  end
  scope module: :lien_filings do
    resources :lien_filings, only: %i[index show new create]
  end
  scope module: :titling do
    resources :title_applications, only: %i[index show new create] do
      post :advance_status, on: :member
    end
  end
  namespace :dealer_portal do
    resources :deliveries, only: :index
  end
  resources :jurisdictions, only: %i[index show], param: :code
  namespace :api do
    namespace :v1 do
      resources :jurisdictions, only: %i[index show], param: :code
      resources :temp_tags, only: :create, param: :tag_number
      get "temp_tags/:tag_number", to: "temp_tags#show"
      post "registration_quotes", to: "registration_quotes#create"
      post "lien_determinations", to: "lien_determinations#create"
    end
  end
  get "/api/v1", to: "api/v1/errors#not_found"
  match "/api/v1/*path", to: "api/v1/errors#not_found", via: :all
end
