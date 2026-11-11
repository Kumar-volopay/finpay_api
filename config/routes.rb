require "ipaddr"

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
  if Rails.env.production?
    allowed_ips = ENV.fetch("SIDEKIQ_ALLOWED_IPS", "")
                     .split(",")
                     .filter_map do |ip|
      IPAddr.new(ip.strip)
    rescue IPAddr::InvalidAddressError
      nil
    end

    constraints lambda { |request|
      begin
        client_ip = IPAddr.new(request.remote_ip)
        allowed_ips.any? { |allowed_ip| allowed_ip.include?(client_ip) }
      rescue IPAddr::InvalidAddressError
        false
      end
    } do
      mount Sidekiq::Web => "/sidekiq"
    end
  else
    mount Sidekiq::Web => "/sidekiq"
  end

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :expenses, only: %i[index show create update destroy] do
        member do
          post :approve
          post :reject
          post :reimburse
          post :archive
        end
        resources :receipts, only: %i[create show], controller: "receipts"
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
