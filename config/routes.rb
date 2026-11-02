Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :expenses, only: %i[index show create update destroy] do
        post :approve, on: :member
        post :reject, on: :member
        post :reimburse, on: :member
      end
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      delete "auth/logout", to: "auth#logout"
      post "auth/refresh", to: "auth#refresh"
      post "invitations", to: "invitations#create"

      get "protected", to: "protected#index"
      get "users/:id", to: "users#show"
    end
  end
end
