Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      delete "auth/logout", to: "auth#logout"
      post "auth/refresh", to: "auth#refresh"

      get "protected", to: "protected#index"
      get "users/:id", to: "users#show"
    end
  end
end
